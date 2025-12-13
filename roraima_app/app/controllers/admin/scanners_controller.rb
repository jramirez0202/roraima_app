# frozen_string_literal: true

module Admin
  # Controller para manejo de escáner de códigos QR/barras
  # Optimizado para dispositivos Zebra TC15 y similares (modo HID keyboard)
  class ScannersController < Admin::BaseController
    # GET /admin/scanner o /admin/scanner/warehouse
    def warehouse_scanner
      # Vista simple, no requiere cargar datos
      # Las estadísticas se cargan vía JSON si es necesario
    end

    # POST /admin/scanner/process
    # Endpoint AJAX para procesar códigos escaneados
    def process_scan
      tracking_input = params[:tracking_input]&.strip

      # === RATE LIMITING ===
      # Prevenir escaneos demasiado rápidos (Zebra TC15 puede enviar Enter múltiples veces)
      last_scan_at = session[:last_scan_at]&.to_time
      if last_scan_at && (Time.current - last_scan_at) < 0.3 # 300ms mínimo
        render json: {
          success: false,
          error: 'Escaneo demasiado rápido, espera un momento'
        }, status: :too_many_requests
        return
      end

      # === INPUT VALIDATION ===
      if tracking_input.blank?
        render json: {
          success: false,
          error: 'Código de seguimiento vacío'
        }, status: :unprocessable_entity
        return
      end

      # === EXTRACT TRACKING CODE ===
      tracking_code = extract_tracking_code(tracking_input)

      unless tracking_code
        render json: {
          success: false,
          error: 'Formato de código inválido. Esperado: PKG-XXXXXXXXXXXXXX'
        }, status: :unprocessable_entity
        return
      end

      # === FIND PACKAGE ===
      # Usa trigram index para búsqueda rápida
      packages = policy_scope(Package).search_by_tracking(tracking_code)
      package = packages.first

      unless package
        render json: {
          success: false,
          error: "Paquete no encontrado: #{tracking_code}"
        }, status: :not_found
        return
      end

      # === CHECK PERMISSIONS ===
      authorize package, :change_status?

      # === CHECK IF ALREADY IN WAREHOUSE ===
      if package.in_warehouse?
        render json: {
          success: true,
          warning: true,
          message: 'Paquete ya estaba en bodega',
          package: package_summary(package)
        }
        return
      end

      # === VALIDATE TRANSITION ===
      unless package.can_transition_to?(:in_warehouse)
        current_status_text = helpers.status_text(package.status)
        render json: {
          success: false,
          error: "No se puede mover a bodega desde estado: #{current_status_text}",
          current_status: package.status,
          tracking_code: package.tracking_code
        }, status: :unprocessable_entity
        return
      end

      # === EXECUTE TRANSITION ===
      service = PackageStatusService.new(package, current_user)

      if service.change_status(
        :in_warehouse,
        reason: 'Escaneado en bodega',
        location: 'Bodega Principal'
      )
        # Update session stats
        session[:last_scan_at] = Time.current
        session[:scan_count] ||= 0
        session[:scan_count] += 1

        render json: {
          success: true,
          message: 'Paquete ingresado a bodega exitosamente',
          package: package_summary(package.reload),
          session_count: session[:scan_count]
        }
      else
        render json: {
          success: false,
          error: service.errors.join(', ')
        }, status: :unprocessable_entity
      end

    rescue JSON::ParserError
      render json: {
        success: false,
        error: 'Código QR con formato JSON inválido'
      }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Scanner error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: {
        success: false,
        error: 'Error interno del servidor'
      }, status: :internal_server_error
    end

    # GET /admin/scanner/session_stats
    # Retorna estadísticas de la sesión actual
    def session_stats
      render json: {
        scan_count: session[:scan_count] || 0,
        started_at: session[:scan_session_started_at] || Time.current
      }
    end

    # POST /admin/scanner/reset_session
    # Reinicia contadores de sesión
    def reset_session
      session[:scan_count] = 0
      session[:scan_session_started_at] = Time.current
      session.delete(:last_scan_at)

      render json: { success: true }
    end

    private

    # Extrae el tracking code de varios formatos de input
    # Acepta:
    # 1. Tracking code plano: "PKG-86169301226465"
    # 2. JSON del QR: {"tracking":"PKG-86169301226465",...}
    # 3. Con whitespace/newlines (se limpian)
    def extract_tracking_code(input)
      return nil if input.blank?

      cleaned = input.strip

      # Caso 1: Tracking code plano
      return cleaned if cleaned.match?(/^PKG-\d{14}$/)

      # Caso 2: JSON del QR code
      if cleaned.start_with?('{') || cleaned.start_with?('[')
        begin
          json_data = JSON.parse(cleaned)
          # Manejar tanto objeto único como array
          data = json_data.is_a?(Array) ? json_data.first : json_data
          tracking = data['tracking'] || data[:tracking]
          return tracking if tracking&.match?(/^PKG-\d{14}$/)
        rescue JSON::ParserError
          # Fall through a return nil
        end
      end

      # Caso 3: Intentar encontrar patrón PKG- en cualquier parte del string
      match = cleaned.match(/PKG-\d{14}/)
      match ? match[0] : nil
    end

    # Retorna resumen del paquete para respuesta JSON
    def package_summary(package)
      {
        id: package.id,
        tracking_code: package.tracking_code,
        customer_name: package.customer_name,
        address: package.address,
        commune: package.commune.name,
        previous_status: package.previous_status,
        current_status: package.status,
        status_text: helpers.status_text(package.status),
        scanned_at: Time.current.strftime('%H:%M:%S')
      }
    end
  end
end
