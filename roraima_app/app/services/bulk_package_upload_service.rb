require 'roo'

class BulkPackageUploadService
  attr_reader :bulk_upload, :errors

  # Mapeo de columnas esperadas en el archivo
  EXPECTED_HEADERS = {
    'FECHA' => :loading_date,
    'DESTINATARIO' => :customer_name,
    'TELÉFONO' => :phone,
    'TELEFONO' => :phone, # Alternativa sin tilde
    'DIRECCIÓN' => :address,
    'DIRECCION' => :address, # Alternativa sin tilde
    'COMUNA' => :commune,
    'DESCRIPCIÓN' => :description,
    'DESCRIPCION' => :description, # Alternativa sin tilde
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
  end

  def process
    begin
      bulk_upload.update!(status: :processing)

      # Abrir el archivo con Roo
      spreadsheet = open_spreadsheet
      headers = normalize_headers(spreadsheet.row(1))

      # Validar que existan los headers requeridos
      unless valid_headers?(headers)
        add_error(0, 'estructura', '', 'El archivo no tiene las columnas requeridas')
        finalize_with_error
        return false
      end

      # Calcular el total de filas y guardarlo para el progreso
      total_file_rows = spreadsheet.last_row - 1 # Restar la fila de headers
      bulk_upload.update!(total_rows: total_file_rows, started_at: Time.current)

      # Procesar cada fila (empezando desde la fila 2, ya que 1 son los headers)
      (2..spreadsheet.last_row).each do |row_number|
        @total_rows += 1
        row_data = Hash[headers.zip(spreadsheet.row(row_number))]
        process_row(row_number, row_data)

        # Actualizar progreso cada 5 filas o en la última fila
        if @total_rows % 5 == 0 || row_number == spreadsheet.last_row
          bulk_upload.update!(
            processed_count: @total_rows,
            current_row: row_number,
            successful_rows: @successful_rows,
            failed_rows: @failed_rows
          )
          bulk_upload.broadcast_progress
        end
      end

      finalize_success
      true
    rescue => e
      Rails.logger.error "BulkUpload #{bulk_upload.id} falló: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Mensaje de error más amigable
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

  def open_spreadsheet
    file_path = bulk_upload.file.blob.service.path_for(bulk_upload.file.key)

    case bulk_upload.file.content_type
    when 'text/csv'
      Roo::CSV.new(file_path)
    when 'application/vnd.ms-excel'
      Roo::Excel.new(file_path)
    when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      Roo::Excelx.new(file_path)
    else
      raise "Formato de archivo no soportado: #{bulk_upload.file.content_type}"
    end
  end

  def normalize_headers(header_row)
    header_row.map do |header|
      normalized = header.to_s.strip.upcase
      EXPECTED_HEADERS[normalized] || normalized
    end
  end

  def valid_headers?(headers)
    required_fields = [:loading_date, :customer_name, :phone, :address, :commune, :description, :amount, :exchange, :sender_email]
    required_fields.all? { |field| headers.include?(field) }
  end

  def process_row(row_number, row_data)
    begin
      # Transformar datos
      package_params = build_package_params(row_number, row_data)
      return unless package_params # Si hubo errores en la construcción, ya se registraron

      # Crear el package con user_id explícito
      package = Package.new(package_params)

      if package.save
        @successful_rows += 1
      else
        @failed_rows += 1
        package.errors.full_messages.each do |error_message|
          add_error(row_number, 'validación', '', error_message)
        end
      end
    rescue => e
      @failed_rows += 1
      add_error(row_number, 'error', '', e.message)
    end
  end

  def build_package_params(row_number, row_data)
    params = {}
    has_errors = false

    # FECHA -> loading_date
    begin
      date_value = row_data[:loading_date]
      if date_value.blank?
        add_error(row_number, 'FECHA', date_value, 'no puede estar vacío')
        has_errors = true
      elsif date_value.is_a?(Date) || date_value.is_a?(DateTime)
        params[:loading_date] = date_value.to_date
      elsif date_value.is_a?(String)
        params[:loading_date] = Date.parse(date_value) rescue nil
        if params[:loading_date].nil?
          add_error(row_number, 'FECHA', date_value, 'formato de fecha inválido')
          has_errors = true
        end
      else
        # Puede ser un número de Excel (días desde 1900-01-01)
        params[:loading_date] = Date.new(1899, 12, 30) + date_value.to_i rescue nil
        if params[:loading_date].nil?
          add_error(row_number, 'FECHA', date_value, 'formato de fecha inválido')
          has_errors = true
        end
      end
    rescue => e
      add_error(row_number, 'FECHA', date_value, "error al procesar fecha: #{e.message}")
      has_errors = true
    end

    # customer_name
    customer_name = row_data[:customer_name].to_s.strip
    if customer_name.blank?
      add_error(row_number, 'DESTINATARIO', customer_name, 'no puede estar vacío')
      has_errors = true
    else
      params[:customer_name] = customer_name
    end

    # phone - Transformar automáticamente
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

    # address
    address = row_data[:address].to_s.strip
    if address.blank?
      add_error(row_number, 'DIRECCIÓN', address, 'no puede estar vacío')
      has_errors = true
    else
      params[:address] = address[0..99] # Limitar a 100 caracteres
    end

    # commune - Buscar por nombre
    commune_name = row_data[:commune].to_s.strip
    if commune_name.blank?
      add_error(row_number, 'COMUNA', commune_name, 'no puede estar vacío')
      has_errors = true
    else
      commune = find_commune(commune_name)
      if commune.nil?
        add_error(row_number, 'COMUNA', commune_name, 'no existe en el sistema')
        has_errors = true
      else
        params[:commune_id] = commune.id
        params[:region_id] = commune.region_id
      end
    end

    # description
    description = row_data[:description].to_s.strip
    if description.blank?
      add_error(row_number, 'DESCRIPCIÓN', description, 'no puede estar vacío')
      has_errors = true
    else
      params[:description] = description[0..99] # Limitar a 100 caracteres
    end

    # amount
    amount = parse_amount(row_data[:amount])
    if amount.nil?
      add_error(row_number, 'MONTO', row_data[:amount], 'formato de monto inválido')
      has_errors = true
    else
      params[:amount] = amount
    end

    # exchange (boolean)
    exchange_value = row_data[:exchange].to_s.strip.upcase
    params[:exchange] = ['SI', 'SÍ', 'S', 'TRUE', '1', 'YES', 'Y'].include?(exchange_value)

    # sender_email y company_name (lógica diferente para admin vs customer)
    sender_email = row_data[:sender_email].to_s.strip

    # Si el uploader es admin, EMPRESA es obligatorio
    if bulk_upload.user.admin?
      if sender_email.blank?
        add_error(row_number, 'EMPRESA', sender_email, 'no puede estar vacío (debe ser el email del cliente)')
        has_errors = true
      else
        params[:sender_email] = sender_email
        customer = find_customer_by_email(sender_email)
        if customer
          params[:user_id] = customer.id
          params[:company_name] = customer.company
        else
          add_error(row_number, 'EMPRESA', sender_email, 'email no existe o no es un customer válido')
          has_errors = true
        end
      end
    else
      # Si es customer, EMPRESA es opcional/informativo
      params[:sender_email] = sender_email if sender_email.present?
      params[:company_name] = bulk_upload.user.company
      # Siempre asignar al usuario logueado
      params[:user_id] = bulk_upload.user_id
    end

    # Initial status
    params[:status] = :pending_pickup

    # Asignar el bulk_upload_id para trazabilidad
    params[:bulk_upload_id] = bulk_upload.id

    return nil if has_errors
    params
  end

  def normalize_phone(phone)
    # Eliminar espacios, guiones, paréntesis
    cleaned = phone.gsub(/[\s\-\(\)]/, '')

    # Si empieza con +56, verificar que sea +569
    if cleaned.start_with?('+56')
      return cleaned if cleaned.start_with?('+569') && cleaned.length == 12
      # Si es +56 seguido de 9 dígitos, agregar el 9
      return "+569#{cleaned[3..]}" if cleaned.length == 11 && cleaned[3].match?(/[0-9]/)
    end

    # Si empieza con 56 (sin +)
    if cleaned.start_with?('56') && !cleaned.start_with?('+')
      return "+569#{cleaned[3..]}" if cleaned.length == 11 && cleaned[3].match?(/[0-9]/)
    end

    # Si empieza con 9 y tiene 9 dígitos (formato chileno móvil)
    if cleaned.start_with?('9') && cleaned.length == 9
      return "+56#{cleaned}"
    end

    # Si son 8 dígitos, asumir que falta el 9 inicial
    if cleaned.length == 8 && cleaned.match?(/\A\d{8}\z/)
      return "+569#{cleaned}"
    end

    # Si ya tiene el formato correcto
    return cleaned if cleaned.match?(/\A\+569\d{8}\z/)

    # Si no se pudo normalizar, devolver el valor limpio
    cleaned
  end

  def parse_amount(value)
    return 0.0 if value.blank?
    return value.to_f if value.is_a?(Numeric)

    # Si es string, limpiar y parsear
    cleaned = value.to_s.gsub(/[^\d,.]/, '')
    cleaned.gsub!(',', '.') # Convertir coma a punto decimal
    cleaned.to_f rescue nil
  end

  def find_commune(commune_name)
    # Buscar por nombre case-insensitive en Región Metropolitana
    region = Region.find_by('LOWER(name) = ?', 'región metropolitana')
    return nil unless region

    Commune.where(region_id: region.id)
           .where('LOWER(name) = ?', commune_name.downcase)
           .first
  end

  def find_customer_by_email(email)
    # Buscar usuario customer por email (case-insensitive)
    User.where('LOWER(email) = ?', email.downcase)
        .where(role: :customer, active: true)
        .first
  end

  def add_error(row, column, value, error_message)
    @errors << {
      row: row,
      column: column,
      value: value.to_s[0..50], # Limitar longitud del valor
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
