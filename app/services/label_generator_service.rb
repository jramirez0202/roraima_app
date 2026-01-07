require 'prawn'
require 'prawn/qrcode'

class LabelGeneratorService
  LABEL_WIDTH = 283.46   # 10 cm
  LABEL_HEIGHT = 425.19  # 15 cm
  MARGIN = 15

  LOGO_HORIZONTAL_OFFSET = 10
  LOGO_VERTICAL_OFFSET = -15
  LOGO_MAX_WIDTH = 80
  LOGO_MAX_HEIGHT = 40

  MONTO_FONT_SIZE = 10
  MONTO_Y_POSITION = 35
  MONTO_FONT_STYLE = :bold
  MONTO_ALIGN = :center
  MONTO_LEADING = 2

  DEVOLUCION_FONT_SIZE = 10
  DEVOLUCION_Y_POSITION_SOLO = 55
  DEVOLUCION_Y_POSITION_CON_MONTO = 50
  DEVOLUCION_FONT_STYLE = :bold
  DEVOLUCION_ALIGN = :center

  def initialize(packages)
    @packages = Array(packages)
  end

  def generate
    Prawn::Document.new(
      page_size: [LABEL_WIDTH, LABEL_HEIGHT],
      margin: MARGIN
    ) do |pdf|
      @packages.each_with_index do |package, index|
        pdf.start_new_page unless index.zero?
        draw_label(pdf, package)
      end
    end
  end

  private

  def draw_label(pdf, package)
    cursor_y = pdf.cursor

    # HEADER: logo o empresa
    add_company_branding(pdf, package, cursor_y)

    pdf.move_down 3
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    pdf.text "Envío: #{package.tracking_code}", size: 9, style: :bold
    pdf.move_down 2
    pdf.text "Entrega: #{package.loading_date.strftime('%d-%m-%Y')}", size: 9

    pdf.move_down 30
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    qr_size = 90
    spacing = 5
    qr_column_width = qr_size
    comuna_column_width = LABEL_WIDTH - (qr_size + spacing + 2*MARGIN)
    qr_x = 0
    qr_y = pdf.cursor

    pdf.bounding_box([qr_x, qr_y], width: qr_column_width, height: qr_size + 60) do
      begin
        pdf.print_qr_code(package.qr_data, extent: qr_size, pos: [0, qr_size + 60])
      rescue
        pdf.text "Error QR", size: 8
      end

      draw_monto(pdf, package, qr_column_width) if package.amount.positive?
      draw_devolucion(pdf, package, qr_column_width) if package.exchange
    end

    pdf.bounding_box([qr_x + qr_size + spacing, qr_y], width: comuna_column_width, height: qr_size + 2) do
      pdf.text_box(
        package.commune.name.upcase,
        at: [0, (qr_size + 5) / 2 + 5],
        width: comuna_column_width,
        size: 14,
        style: :bold,
        align: :center
      )
    end

    pdf.move_down qr_size + 20
    pdf.stroke_horizontal_rule
    pdf.move_down 5

    pdf.bounding_box([0, pdf.cursor], width: LABEL_WIDTH - 2*MARGIN, height: LABEL_HEIGHT - (pdf.cursor - MARGIN)) do
      pdf.text "Destinatario: #{package.customer_name}", size: 9, style: :bold
      pdf.move_down 1
      pdf.text "Teléfono: #{package.phone}", size: 9
      pdf.move_down 1
      pdf.text "Dirección: #{package.address}", size: 9
      pdf.move_down 1
      description_text = package.description.presence || "Sin indicaciones"
      pdf.text "Indicaciones: #{description_text}", size: 8, leading: 1.2
    end
  end

  def draw_monto(pdf, package, width)
    pdf.text_box(
      "Cobrar:\n#{package.formatted_amount}",
      at: [0, MONTO_Y_POSITION],
      width: width,
      size: MONTO_FONT_SIZE,
      style: MONTO_FONT_STYLE,
      align: MONTO_ALIGN,
      leading: MONTO_LEADING
    )
  end

  def draw_devolucion(pdf, package, width)
    y_position = package.amount.positive? ? DEVOLUCION_Y_POSITION_CON_MONTO : DEVOLUCION_Y_POSITION_SOLO
    pdf.text_box(
      "DEVOLUCIÓN",
      at: [0, y_position],
      width: width,
      size: DEVOLUCION_FONT_SIZE,
      style: DEVOLUCION_FONT_STYLE,
      align: DEVOLUCION_ALIGN
    )
  end

  def add_company_branding(pdf, package, cursor_y)
    user = package.user

    if user&.logo_enabled_for_labels? && user.company_logo.attached?
      begin
        # Usar el logo pre-cargado sin descargas adicionales
        logo_file = get_logo_file(user)
        logo_x_base = LABEL_WIDTH - 2 * MARGIN - LOGO_MAX_WIDTH
        pdf.image(
          logo_file,
          at: [logo_x_base + LOGO_HORIZONTAL_OFFSET, cursor_y + LOGO_VERTICAL_OFFSET],
          fit: [LOGO_MAX_WIDTH, LOGO_MAX_HEIGHT]
        )
        logo_file.unlink if logo_file.is_a?(Tempfile)
      rescue => e
        Rails.logger.error("Error al mostrar logo: #{e.message}")
        show_company_name_fallback(pdf, package, cursor_y)
      end
    else
      show_company_name_fallback(pdf, package, cursor_y)
    end
  end

  def get_logo_file(user)
    blob = user.company_logo.blob
    
  if blob.service.respond_to?(:path_for)
    blob.service.send(:path_for, blob.key)
  else
    temp_file = Tempfile.new(['logo', File.extname(blob.filename.to_s)])
    temp_file.binmode
    temp_file.write(blob.download)
    temp_file.rewind
    temp_file
  end

  def show_company_name_fallback(pdf, package, cursor_y)
    pdf.bounding_box([0, cursor_y], width: LABEL_WIDTH - 2*MARGIN, height: 40) do
      pdf.text(package.company_name.presence || "N/A", size: 11, style: :bold, align: :left)
    end
  end
end