# frozen_string_literal: true

module Admin
  # Controller para manejo de escáner de códigos QR/barras
  # Optimizado para dispositivos Zebra TC15 y similares (modo HID keyboard)
  class ScannersController < Admin::BaseController
    # GET /admin/scanner o /admin/scanner/warehouse
    def warehouse_scanner
      # Cargar lista de clientes para selector (solo customers activos)
      @customers = User.where(role: :customer, active: true)
                       .order(:name)
                       .select(:id, :name, :email, :company)
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
          error: 'Formato de código inválido. Formatos aceptados: PKG, MLB, FLB'
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

      # === SPECIAL CASE: RESCHEDULED PACKAGES ===
      # Paquetes reprogramados al ser escaneados vuelven a bodega automáticamente
      if package.rescheduled?
        service = PackageStatusService.new(package, current_user)

        if service.change_status(
          :in_warehouse,
          reason: 'Paquete reprogramado regresado a bodega',
          location: 'Bodega Principal'
        )
          session[:last_scan_at] = Time.current
          session[:scan_count] ||= 0
          session[:scan_count] += 1

          render json: {
            success: true,
            message: 'Paquete reprogramado ingresado a bodega exitosamente',
            package: package_summary(package.reload),
            session_count: session[:scan_count]
          }
          return
        else
          render json: {
            success: false,
            error: service.errors.join(', ')
          }, status: :unprocessable_entity
          return
        end
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

    # POST /admin/scanner/create_package
    # Crea un paquete nuevo con solo el tracking code escaneado
    def create_package
      tracking_input = params[:tracking_input]&.strip

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
          error: 'Formato de código inválido. Formatos aceptados: PKG, MLB, FLB'
        }, status: :unprocessable_entity
        return
      end

      # === DETECT PROVIDER ===
      provider = Package.detect_provider(tracking_code)
      unless provider
        render json: {
          success: false,
          error: 'No se pudo detectar el proveedor del código escaneado'
        }, status: :unprocessable_entity
        return
      end

      # === CHECK IF ALREADY EXISTS ===
      existing_package = Package.find_by(tracking_code: tracking_code, provider: provider)
      if existing_package
        render json: {
          success: false,
          error: 'Este paquete ya existe en el sistema',
          package_id: existing_package.id,
          redirect_url: admin_package_path(existing_package)
        }, status: :unprocessable_entity
        return
      end

      # === GET CUSTOMER ===
      customer_id = params[:customer_id]

      unless customer_id.present?
        render json: {
          success: false,
          error: 'Debe seleccionar un cliente antes de crear el paquete'
        }, status: :unprocessable_entity
        return
      end

      customer = User.find_by(id: customer_id, role: :customer)

      unless customer
        render json: {
          success: false,
          error: 'Cliente no encontrado o no es válido'
        }, status: :unprocessable_entity
        return
      end

      # === GET DEFAULT REGION AND COMMUNE ===
      # Región Metropolitana como default
      default_region = Region.find_by(name: 'Región Metropolitana de Santiago') || Region.first
      default_commune = default_region.communes.find_by(name: 'Santiago') || default_region.communes.first

      # === DETERMINE INITIAL STATUS ===
      # FLB y MLB ya están en bodega cuando se escanean
      # PKG (Roraima) están pendientes de retiro
      initial_status = %w[FLB MLB].include?(provider) ? :in_warehouse : :pending_pickup

      # === CREATE PACKAGE ===
      package = Package.new(
        tracking_code: tracking_code,
        provider: provider,
        user: customer,
        region: default_region,
        commune: default_commune,
        phone: customer.phone || '+56900000000',  # Usar teléfono del cliente o placeholder
        loading_date: Date.current,
        status: initial_status,
        amount: 0,
        customer_name: customer.name || 'Por Asignar',
        address: 'Por Asignar'
      )

      if package.save
        # Update session stats
        session[:last_scan_at] = Time.current
        session[:scan_count] ||= 0
        session[:scan_count] += 1

        status_message = initial_status == :in_warehouse ? "registrado en bodega" : "registrado como pendiente retiro"

        render json: {
          success: true,
          message: "Paquete #{provider} #{status_message} para #{customer.name}",
          package: package_summary(package),
          session_count: session[:scan_count]
        }
      else
        render json: {
          success: false,
          error: "Error al crear el paquete: #{package.errors.full_messages.join(', ')}"
        }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Error creating package: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: {
        success: false,
        error: 'Error interno al crear el paquete'
      }, status: :internal_server_error
    end

    private

    # Extrae el tracking code y detecta el provider automáticamente
    # Acepta:
    # 1. Tracking code plano: "PKG-86169301226465" (Rutiservice), "46228651544" (Mercado Libre), o "3219053220" (Falabella)
    # 2. JSON del QR: {"tracking":"PKG-86169301226465",...}
    # 3. Con whitespace/newlines (se limpian)
    def extract_tracking_code(input)
      return nil if input.blank?

      cleaned = input.strip

      # Caso 1: Detectar provider desde código plano
      provider = Package.detect_provider(cleaned)
      return cleaned if provider

      # Caso 2: JSON del QR code
      if cleaned.start_with?('{') || cleaned.start_with?('[')
        begin
          json_data = JSON.parse(cleaned)
          data = json_data.is_a?(Array) ? json_data.first : json_data
          # Buscar en múltiples claves posibles: "tracking", "id" (Mercado Libre usa "id")
          tracking = data['tracking'] || data[:tracking] || data['id'] || data[:id]

          if tracking
            provider = Package.detect_provider(tracking)
            return tracking if provider
          end
        rescue JSON::ParserError
          # Fall through
        end
      end

      # Caso 3: Buscar cualquier patrón válido en el string
      Package::PROVIDER_PATTERNS.each do |provider_name, pattern|
        match = cleaned.match(pattern)
        return match[0] if match
      end

      nil
    end

    # Retorna resumen del paquete para respuesta JSON
    def package_summary(package)
      {
        id: package.id,
        tracking_code: package.tracking_code,
        provider: package.provider,
        provider_name: package.provider_name,
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
