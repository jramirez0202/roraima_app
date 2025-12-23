# frozen_string_literal: true

module Drivers
  # Controller para manejo de escáner de códigos QR/barras para drivers
  # Permite escanear paquetes para cambiar estados durante la ruta
  class ScannersController < ApplicationController
    before_action :require_driver!

    # GET /drivers/scanner
    def warehouse_scanner
      # Vista simple, no requiere cargar datos
    end

    # POST /drivers/scanner/process
    # Endpoint AJAX para procesar códigos escaneados
    def process_scan
      tracking_input = params[:tracking_input]&.strip

      # === RATE LIMITING ===
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
      # Buscar en TODOS los paquetes (no solo asignados al driver)
      packages = Package.search_by_tracking(tracking_code)
      package = packages.first

      unless package
        render json: {
          success: false,
          error: "Paquete no encontrado: #{tracking_code}"
        }, status: :not_found
        return
      end

      # === LÓGICA DINÁMICA DE ASIGNACIÓN Y ESTADO ===

      service = PackageStatusService.new(package, current_user)
      action_taken = nil

      # CASO 1: Paquete en bodega (in_warehouse) → Asignar al driver y cambiar a in_transit
      # ✅ NO REQUIERE RUTA ACTIVA (permite preparar carga antes de salir)
      if package.in_warehouse?
        # Asignar al driver que lo escaneó
        if service.assign_courier(current_user.id)
          action_taken = "Paquete asignado y marcado como 'En Camino'"
        else
          render json: {
            success: false,
            error: "Error al asignar paquete: #{service.errors.join(', ')}"
          }, status: :unprocessable_entity
          return
        end

      # CASO 2: Paquete en tránsito de otro driver → Reasignar al driver actual
      # ⚠️ REQUIERE RUTA ACTIVA (solo reasignaciones en campo)
      elsif package.in_transit? && package.assigned_courier_id != current_user.id
        # Validar que el driver tenga ruta activa para reasignaciones
        unless current_user.on_route?
          render json: {
            success: false,
            error: 'Debes iniciar tu ruta antes de reasignar paquetes de otros drivers'
          }, status: :unprocessable_entity
          return
        end

        previous_driver = package.assigned_courier

        # Registrar cambio de driver en historial
        package.add_to_history(
          status: package.status,
          user_id: current_user.id,
          reason: "Paquete reasignado desde #{previous_driver&.name || 'otro driver'} mediante escaneo",
          location: 'Reasignación por escaneo'
        )
        package.save!

        # Reasignar al nuevo driver
        if service.assign_courier(current_user.id)
          action_taken = "Paquete reasignado desde #{previous_driver&.name || 'otro driver'}"
        else
          render json: {
            success: false,
            error: "Error al reasignar paquete: #{service.errors.join(', ')}"
          }, status: :unprocessable_entity
          return
        end

      # CASO 3: Paquete ya asignado a este driver y en tránsito → No hacer nada
      elsif package.in_transit? && package.assigned_courier_id == current_user.id
        session[:last_scan_at] = Time.current

        render json: {
          success: true,
          warning: true,
          message: 'Paquete ya está asignado a ti y en camino',
          package: package_summary(package)
        }
        return

      # CASO 4: Paquete en otro estado → No permitir
      else
        current_status_text = helpers.status_text(package.status)
        render json: {
          success: false,
          error: "No se puede escanear paquete en estado: #{current_status_text}. Solo se pueden escanear paquetes en 'Bodega' o 'En Camino'.",
          current_status: package.status,
          tracking_code: package.tracking_code
        }, status: :unprocessable_entity
        return
      end

      # === SUCCESS RESPONSE ===
      session[:last_scan_at] = Time.current
      session[:scan_count] ||= 0
      session[:scan_count] += 1

      render json: {
        success: true,
        message: action_taken,
        package: package_summary(package.reload),
        session_count: session[:scan_count]
      }

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

    # GET /drivers/scanner/session_stats
    def session_stats
      render json: {
        scan_count: session[:scan_count] || 0,
        started_at: session[:scan_session_started_at] || Time.current
      }
    end

    # POST /drivers/scanner/reset_session
    def reset_session
      session[:scan_count] = 0
      session[:scan_session_started_at] = Time.current
      session.delete(:last_scan_at)

      render json: { success: true }
    end

    private

    # Extrae el tracking code de varios formatos de input
    def extract_tracking_code(input)
      return nil if input.blank?

      cleaned = input.strip

      # Caso 1: Tracking code plano
      return cleaned if cleaned.match?(/^PKG-\d{14}$/)

      # Caso 2: JSON del QR code
      if cleaned.start_with?('{') || cleaned.start_with?('[')
        begin
          json_data = JSON.parse(cleaned)
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

    def require_driver!
      unless current_user&.driver?
        redirect_to root_path, alert: 'Acceso no autorizado'
      end
    end
  end
end
