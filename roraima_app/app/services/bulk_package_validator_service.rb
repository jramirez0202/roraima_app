require 'roo'

class BulkPackageValidatorService
  attr_reader :errors, :total_rows, :validated_rows

  # Mapeo de columnas esperadas en el archivo (reutilizado de BulkPackageUploadService)
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
    'EMPRESA' => :company
  }.freeze

  MAX_ROWS_TO_VALIDATE = 100

  def initialize(file_attachment, user)
    @file_attachment = file_attachment
    @user = user
    @errors = []
    @total_rows = 0
    @validated_rows = 0
  end

  def validate
    begin
      spreadsheet = open_spreadsheet
      headers = normalize_headers(spreadsheet.row(1))

      # Validar que existan los headers requeridos
      unless valid_headers?(headers)
        add_error(0, 'estructura', '', 'El archivo no tiene las columnas requeridas. Columnas esperadas: FECHA, DESTINATARIO, TELÉFONO, DIRECCIÓN, COMUNA, DESCRIPCIÓN, MONTO, CAMBIO, EMPRESA')
        return false
      end

      # Calcular total de filas
      @total_rows = spreadsheet.last_row - 1 # Restar header

      # Determinar cuántas filas validar
      rows_to_validate = [@total_rows, MAX_ROWS_TO_VALIDATE].min

      # Validar cada fila (hasta el límite)
      (2..[spreadsheet.last_row, MAX_ROWS_TO_VALIDATE + 1].min).each do |row_number|
        @validated_rows += 1
        row_data = Hash[headers.zip(spreadsheet.row(row_number))]
        validate_row(row_number, row_data)
      end

      # Si hay errores, retornar false
      @errors.empty?
    rescue => e
      Rails.logger.error "Error al validar archivo: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Mensaje de error más amigable
      error_message = if e.message.include?("not an Excel 2007 file")
        "El archivo XLSX no es válido o está corrupto. Por favor descarga la plantilla XLSX desde el botón 'XLSX' y úsala como base, o usa el formato CSV."
      elsif e.message.include?("Invalid header")
        "El archivo no tiene las columnas esperadas. Por favor descarga la plantilla y asegúrate de mantener los nombres de las columnas exactos."
      else
        "Error al procesar el archivo: #{e.message}. Si el problema persiste, intenta usar el formato CSV."
      end

      add_error(0, 'sistema', '', error_message)
      false
    end
  end

  def valid?
    @errors.empty?
  end

  def has_more_rows?
    @total_rows > MAX_ROWS_TO_VALIDATE
  end

  private

  def open_spreadsheet
    file_path = @file_attachment.blob.service.path_for(@file_attachment.key)

    case @file_attachment.content_type
    when 'text/csv'
      Roo::CSV.new(file_path)
    when 'application/vnd.ms-excel'
      Roo::Excel.new(file_path)
    when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      Roo::Excelx.new(file_path)
    else
      raise "Formato de archivo no soportado: #{@file_attachment.content_type}"
    end
  end

  def normalize_headers(header_row)
    header_row.map do |header|
      normalized = header.to_s.strip.upcase
      EXPECTED_HEADERS[normalized] || normalized
    end
  end

  def valid_headers?(headers)
    required_fields = [:loading_date, :customer_name, :phone, :address, :commune, :description, :amount, :exchange, :company]
    required_fields.all? { |field| headers.include?(field) }
  end

  def validate_row(row_number, row_data)
    # FECHA -> loading_date
    validate_loading_date(row_number, row_data[:loading_date])

    # DESTINATARIO -> customer_name
    validate_customer_name(row_number, row_data[:customer_name])

    # TELÉFONO -> phone
    validate_phone(row_number, row_data[:phone])

    # DIRECCIÓN -> address
    validate_address(row_number, row_data[:address])

    # COMUNA -> commune
    validate_commune(row_number, row_data[:commune])

    # DESCRIPCIÓN -> description
    validate_description(row_number, row_data[:description])

    # MONTO -> amount
    validate_amount(row_number, row_data[:amount])

    # EMPRESA -> company
    validate_company(row_number, row_data[:company])
  end

  def validate_loading_date(row_number, date_value)
    if date_value.blank?
      add_error(row_number, 'FECHA', date_value, 'no puede estar vacío')
      return
    end

    begin
      if date_value.is_a?(Date) || date_value.is_a?(DateTime)
        # Fecha válida
      elsif date_value.is_a?(String)
        parsed_date = Date.parse(date_value) rescue nil
        if parsed_date.nil?
          add_error(row_number, 'FECHA', date_value, 'formato de fecha inválido. Use formato YYYY-MM-DD (ejemplo: 2025-12-31)')
        end
      else
        # Puede ser un número de Excel (días desde 1900-01-01)
        parsed_date = Date.new(1899, 12, 30) + date_value.to_i rescue nil
        if parsed_date.nil?
          add_error(row_number, 'FECHA', date_value, 'formato de fecha inválido. Use formato YYYY-MM-DD (ejemplo: 2025-12-31)')
        end
      end
    rescue => e
      add_error(row_number, 'FECHA', date_value, "error al procesar fecha: #{e.message}")
    end
  end

  def validate_customer_name(row_number, customer_name)
    customer_name_str = customer_name.to_s.strip
    if customer_name_str.blank?
      add_error(row_number, 'DESTINATARIO', customer_name, 'no puede estar vacío')
    end
  end

  def validate_phone(row_number, phone_value)
    phone = normalize_phone(phone_value.to_s.strip)
    if phone.blank?
      add_error(row_number, 'TELÉFONO', phone_value, 'no puede estar vacío')
    elsif !phone.match?(/\A\+569\d{8}\z/)
      add_error(row_number, 'TELÉFONO', phone_value, "formato inválido. Use formato +56912345678 o 912345678")
    end
  end

  def validate_address(row_number, address_value)
    address = address_value.to_s.strip
    if address.blank?
      add_error(row_number, 'DIRECCIÓN', address_value, 'no puede estar vacío')
    end
  end

  def validate_commune(row_number, commune_value)
    commune_name = commune_value.to_s.strip
    if commune_name.blank?
      add_error(row_number, 'COMUNA', commune_value, 'no puede estar vacío')
    else
      commune = find_commune(commune_name)
      if commune.nil?
        add_error(row_number, 'COMUNA', commune_value, 'no existe en el sistema. Debe ser una comuna de la Región Metropolitana')
      end
    end
  end

  def validate_description(row_number, description_value)
    description = description_value.to_s.strip
    if description.blank?
      add_error(row_number, 'DESCRIPCIÓN', description_value, 'no puede estar vacío')
    end
  end

  def validate_amount(row_number, amount_value)
    amount = parse_amount(amount_value)
    if amount.nil?
      add_error(row_number, 'MONTO', amount_value, 'formato de monto inválido. Use números (ejemplo: 15000 o 15000.50)')
    end
  end

  def validate_company(row_number, company_value)
    # Solo validar EMPRESA si es admin
    # Para customers, el campo es opcional/informativo ya que se asigna al usuario logueado
    return unless @user.admin?

    company = company_value.to_s.strip
    if company.blank?
      add_error(row_number, 'EMPRESA', company_value, 'no puede estar vacío (debe ser el email del cliente)')
      return
    end

    # Validar que el email del customer exista
    customer = find_customer_by_email(company)
    if customer.nil?
      add_error(row_number, 'EMPRESA', company_value, 'el email no existe o no corresponde a un cliente activo')
    end
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
end
