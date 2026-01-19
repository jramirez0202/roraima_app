require 'roo'
require_relative 'concerns/spreadsheet_opener'
class BulkPackageUploadService
  attr_reader :bulk_upload, :errors
  
  BATCH_SIZE = 500  # Insertar de a 500 paquetes por transacción
  PROGRESS_UPDATE_INTERVAL = 100  # Actualizar progreso cada 100 filas

  EXPECTED_HEADERS = {
    'DESTINATARIO' => :customer_name,
    'TELÉFONO' => :phone,
    'TELEFONO' => :phone,
    'DIRECCIÓN' => :address,
    'DIRECCION' => :address,
    'COMUNA' => :commune,
    'DESCRIPCIÓN' => :description,
    'DESCRIPCION' => :description,
    'MONTO' => :amount,
    'CAMBIO' => :exchange,
    'EMPRESA' => :sender_email
  }.freeze

  def initialize(bulk_upload)
    @bulk_upload = bulk_upload
    @errors = []
    @successful_rows = 0
    @failed_rows = 0
    @total_rows = 0
    @packages_batch = []  # Acumular paquetes para batch insert
    
    # PRECARGA en MEMORIA (solo 3 queries)
    @region = Region.find_by('LOWER(name) = ?', 'región metropolitana')
    @communes_by_name = build_communes_index
    @customers_by_email = build_customers_index
  end

  def process
    begin
      bulk_upload.update!(status: :processing)

      spreadsheet = open_spreadsheet
      headers = normalize_headers(spreadsheet.row(1))

      unless valid_headers?(headers)
        add_error(0, 'estructura', '', 'El archivo no tiene las columnas requeridas')
        finalize_with_error
        return false
      end

      total_file_rows = spreadsheet.last_row - 1
      bulk_upload.update!(total_rows: total_file_rows, started_at: Time.current)

      # LEER y VALIDAR todas las filas
      (2..spreadsheet.last_row).each do |row_number|
        @total_rows += 1
        row_data = Hash[headers.zip(spreadsheet.row(row_number))]
        process_row(row_number, row_data)

        # Insertar en batch cuando lleguemos a BATCH_SIZE
        if @packages_batch.size >= BATCH_SIZE
          flush_batch
        end

        # Actualizar progreso
        if @total_rows % PROGRESS_UPDATE_INTERVAL == 0 || row_number == spreadsheet.last_row
          bulk_upload.update!(
            processed_count: @total_rows,
            current_row: row_number,
            successful_rows: @successful_rows,
            failed_rows: @failed_rows
          )
          bulk_upload.broadcast_progress
        end
      end

      # Insertar último batch
      flush_batch if @packages_batch.any?

      finalize_success
      true
    rescue => e
      Rails.logger.error "BulkUpload #{bulk_upload.id} falló: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      error_message = if e.message.include?("not an Excel 2007 file")
        "El archivo XLSX no es válido o está corrupto. Por favor descarga la plantilla XLSX oficial y úsala como base."
      elsif e.message.include?("Invalid header")
        "El archivo no tiene las columnas esperadas. Descarga la plantilla y mantén los nombres de las columnas exactos."
      else
        "Error del sistema: #{e.message}"
      end

      add_error(0, 'sistema', '', error_message)
      finalize_with_error
      false
    end
  end

  private

  # BATCH INSERT - Una sola transacción para múltiples paquetes
  def flush_batch
    return if @packages_batch.empty?

    begin
      Package.insert_all(@packages_batch)  # ← Inserción masiva
      @successful_rows += @packages_batch.size
    rescue => e
      Rails.logger.error "Error en batch insert: #{e.message}"
      # Si falla el batch, intentar uno por uno para identificar el error
      @packages_batch.each do |package_params|
        package = Package.new(package_params)
        if package.save
          @successful_rows += 1
        else
          @failed_rows += 1
          package.errors.full_messages.each do |error_message|
            add_error(0, 'validación', '', error_message)
          end
        end
      end
    end

    @packages_batch.clear
  end

  # BUILD INDEXES (solo 3 queries al inicio)
  def build_communes_index
    return {} unless @region
    
    Commune.where(region_id: @region.id)
           .each_with_object({}) do |commune, hash|
      normalized = normalize_commune_name(commune.name).downcase
      hash[normalized] = commune
    end
  end

  def build_customers_index
    User.where(role: :customer, active: true)
        .each_with_object({}) do |user, hash|
      hash[user.email.downcase] = user
    end
  end

  def open_spreadsheet
    SpreadsheetOpener.open_from_attachment(bulk_upload.file)
  end

  def normalize_headers(header_row)
    header_row.map do |header|
      normalized = header.to_s.strip.upcase
      EXPECTED_HEADERS[normalized] || normalized
    end
  end

  def valid_headers?(headers)
    required_fields = [:customer_name, :phone, :address, :commune, :description, :amount, :exchange, :sender_email]
    required_fields.all? { |field| headers.include?(field) }
  end

  def process_row(row_number, row_data)
    begin
      package_params = build_package_params(row_number, row_data)
      return if package_params.nil?

      # En lugar de guardar, agregar al batch
      @packages_batch << package_params
    rescue => e
      @failed_rows += 1
      add_error(row_number, 'error', '', e.message)
    end
  end

  def build_package_params(row_number, row_data)
    params = {}
    has_errors = false

    customer_name = row_data[:customer_name].to_s.strip
    if customer_name.blank?
      add_error(row_number, 'DESTINATARIO', customer_name, 'no puede estar vacío')
      has_errors = true
    else
      params[:customer_name] = customer_name
    end

    phone = normalize_phone(row_data[:phone].to_s.strip)
    if phone.blank?
      add_error(row_number, 'TELÉFONO', row_data[:phone], 'no puede estar vacío')
      has_errors = true
    elsif !phone.match?(/\A\+569\d{8}\z/)
      add_error(row_number, 'TELÉFONO', row_data[:phone], "formato inválido después de transformación: #{phone}")
      has_errors = true
    else
      params[:phone] = phone
    end

    address = row_data[:address].to_s.strip
    if address.blank?
      add_error(row_number, 'DIRECCIÓN', address, 'no puede estar vacío')
      has_errors = true
    else
      params[:address] = address[0..99]
    end

    commune_name = row_data[:commune].to_s.strip
    if commune_name.blank?
      add_error(row_number, 'COMUNA', commune_name, 'no puede estar vacío')
      has_errors = true
    else
      normalized_commune = normalize_commune_name(commune_name).downcase
      commune = @communes_by_name[normalized_commune]
      
      if commune.nil?
        add_error(row_number, 'COMUNA', commune_name, 'no existe en el sistema')
        has_errors = true
      else
        params[:commune_id] = commune.id
        params[:region_id] = commune.region_id
      end
    end

    description = row_data[:description].to_s.strip
    if description.blank?
      add_error(row_number, 'DESCRIPCIÓN', description, 'no puede estar vacío')
      has_errors = true
    else
      params[:description] = description[0..99]
    end

    amount = parse_amount(row_data[:amount])
    if amount.nil?
      add_error(row_number, 'MONTO', row_data[:amount], 'formato de monto inválido')
      has_errors = true
    else
      params[:amount] = amount
    end

    exchange_value = row_data[:exchange].to_s.strip.upcase
    params[:exchange] = ['SI', 'SÍ', 'S', 'TRUE', '1', 'YES', 'Y'].include?(exchange_value)

    sender_email = row_data[:sender_email].to_s.strip

    if bulk_upload.user.admin?
      if sender_email.blank?
        add_error(row_number, 'EMPRESA', sender_email, 'no puede estar vacío (debe ser el email del cliente)')
        has_errors = true
      else
        params[:sender_email] = sender_email
        customer = @customers_by_email[sender_email.downcase]
        
        if customer
          params[:user_id] = customer.id
          params[:company_name] = customer.company
        else
          add_error(row_number, 'EMPRESA', sender_email, 'email no existe o no es un customer válido')
          has_errors = true
        end
      end
    else
      params[:sender_email] = sender_email if sender_email.present?
      params[:company_name] = bulk_upload.user.company
      params[:user_id] = bulk_upload.user_id
    end

    params[:status] = :pending_pickup
    params[:bulk_upload_id] = bulk_upload.id
    params[:created_at] = Time.current
    params[:updated_at] = Time.current

    return nil if has_errors
    params
  end

  def normalize_phone(phone)
    cleaned = phone.gsub(/[\s\-\(\)]/, '')

    if cleaned.start_with?('+56')
      return cleaned if cleaned.start_with?('+569') && cleaned.length == 12
      return "+569#{cleaned[3..]}" if cleaned.length == 11 && cleaned[3].match?(/[0-9]/)
    end

    if cleaned.start_with?('56') && !cleaned.start_with?('+')
      return "+569#{cleaned[3..]}" if cleaned.length == 11 && cleaned[3].match?(/[0-9]/)
    end

    if cleaned.start_with?('9') && cleaned.length == 9
      return "+56#{cleaned}"
    end

    if cleaned.length == 8 && cleaned.match?(/\A\d{8}\z/)
      return "+569#{cleaned}"
    end

    return cleaned if cleaned.match?(/\A\+569\d{8}\z/)

    cleaned
  end

  def parse_amount(value)
    return 0.0 if value.blank?
    return value.to_f if value.is_a?(Numeric)

    cleaned = value.to_s.gsub(/[^\d,.]/, '')
    cleaned.gsub!(',', '.')
    cleaned.to_f rescue nil
  end

  def normalize_commune_name(name)
    aliases = {
      'santiago centro' => 'santiago',
      'stgo' => 'santiago',
      'stgo centro' => 'santiago',
      'estacion central' => 'estación central',
      'ñunoa' => 'ñuñoa',
      'nunoa' => 'ñuñoa',
      'peñalolen' => 'peñalolén',
      'penalolen' => 'peñalolén',
      'maipu' => 'maipú',
      'conchali' => 'conchalí',
      'huechuraba' => 'huechuraba',
      'la florida' => 'la florida',
      'puente alto' => 'puente alto',
      'san bernardo' => 'san bernardo'
    }

    normalized = name.strip.downcase
    aliases[normalized] || name
  end

  def add_error(row, column, value, error_message)
    @errors << {
      row: row,
      column: column,
      value: value.to_s[0..50],
      error: error_message
    }
  end

  def finalize_success
    bulk_upload.update!(
      status: :completed,
      total_rows: @total_rows,
      successful_rows: @successful_rows,
      failed_rows: @failed_rows,
      error_details: @errors,
      processed_at: Time.current
    )
    bulk_upload.broadcast_completion
  end

  def finalize_with_error
    bulk_upload.update!(
      status: :failed,
      total_rows: @total_rows,
      successful_rows: @successful_rows,
      failed_rows: @failed_rows,
      error_details: @errors,
      processed_at: Time.current
    )
    bulk_upload.broadcast_completion
  end
end