# Servicio para manejar el ciclo de vida de rutas de drivers
# Encapsula lógica de negocio y validaciones
class RouteManagementService
  attr_reader :driver, :errors

  def initialize(driver)
    @driver = driver
    @errors = []
  end

  # Inicia ruta con validaciones
  def start_route
    return false unless validate_start_route

    begin
      driver.transaction do
        driver.update!(
          route_status: :on_route,
          route_started_at: Time.current.beginning_of_hour
        )

        # Create new Route record for history tracking
        route = driver.routes.create!(
          started_at: Time.current.beginning_of_hour,
          status: :active,
          packages_delivered: 0
        )

        # Auto-rotate: keep only last 3 routes
        Route.rotate_for_driver(driver.id)

        log_route_event("Route started - Route ID: #{route.id}")
      end
      true
    rescue StandardError => e
      @errors << "Error al iniciar ruta: #{e.message}"
      Rails.logger.error "RouteManagementService#start_route failed: #{e.message}"
      false
    end
  end

  # Completa ruta
  def complete_route(notes: nil)
    return false unless validate_complete_route

    begin
      driver.transaction do
        driver.update!(
          route_status: :completed,
          route_ended_at: Time.current
        )

        # Update current active Route record
        current_route = driver.current_route
        if current_route
          # Calculate packages delivered count
          packages_count = calculate_packages_delivered_in_current_route(current_route)

          current_route.update!(
            ended_at: Time.current,
            status: :completed,
            packages_delivered: packages_count,
            notes: notes
          )

          log_route_event("Route completed - Route ID: #{current_route.id}, Packages: #{packages_count}, Notes: #{notes.present? ? 'Yes' : 'No'}")
        else
          Rails.logger.warn "No active route found for driver #{driver.id} on complete_route"
          log_route_event("Route completed")
        end
      end
      true
    rescue StandardError => e
      @errors << "Error al completar ruta: #{e.message}"
      false
    end
  end

  # Auto-completa ruta si todos los paquetes fueron entregados
  def auto_complete_if_finished
    return false unless driver.on_route?

    progress = driver.route_progress
    return false unless progress[:delivered] >= progress[:total] && progress[:total] > 0

    complete_route
  end

  # Fuerza el cierre de una ruta antigua (solo admins)
  # @param route [Route] La ruta a cerrar
  # @param admin [User] El admin que realiza el cierre
  # @param reason [String] Motivo obligatorio del cierre forzado
  def self.force_close_route(route, admin, reason)
    errors = []

    # Validaciones
    unless admin.admin?
      errors << "Solo los administradores pueden forzar el cierre de rutas"
      return { success: false, errors: errors }
    end

    unless reason.present?
      errors << "El motivo es obligatorio para cerrar una ruta forzadamente"
      return { success: false, errors: errors }
    end

    unless route.active?
      errors << "La ruta ya está cerrada"
      return { success: false, errors: errors }
    end

    begin
      route.transaction do
        # Cerrar la ruta
        route.update!(
          status: :completed,
          ended_at: Time.current,
          closed_by_id: admin.id,
          forced_close_reason: reason,
          forced_closed_at: Time.current
        )

        # Actualizar estado del driver si esta era su ruta activa
        if route.driver.on_route? && route.driver.current_route&.id == route.id
          route.driver.update!(
            route_status: :completed,
            route_ended_at: Time.current
          )
        end

        Rails.logger.info "[RouteManagement] Force close - Route #{route.id} closed by admin #{admin.id} (#{admin.email}). Reason: #{reason}"
      end

      { success: true, errors: [] }
    rescue StandardError => e
      errors << "Error al cerrar ruta: #{e.message}"
      Rails.logger.error "[RouteManagement] Force close failed: #{e.message}"
      { success: false, errors: errors }
    end
  end

  private

  def validate_start_route
    # Only validate authorization if system requires it
    if Setting.require_driver_authorization?
      unless driver.ready_for_route?
        @errors << "El conductor no ha sido marcado como listo por el administrador"
        return false
      end
    end

    if driver.pending_deliveries.count.zero?
      @errors << "No hay paquetes pendientes para entregar"
      return false
    end

    # Solo bloquear si YA está en ruta activa
    # Permitir iniciar nueva ruta desde: not_started, ready, o completed
    if driver.on_route?
      @errors << "Ya tienes una ruta activa en progreso"
      return false
    end

    unless driver.active?
      @errors << "Conductor inactivo, no puede iniciar ruta"
      return false
    end

    true
  end

  def validate_complete_route
    unless driver.on_route?
      @errors << "El conductor no tiene una ruta activa"
      return false
    end

    # Verificar que todos los paquetes estén en estado final
    # Estados finales: delivered, cancelled, return
    # Reprogramados NO bloquean el cierre (son flexibles)
    pending_packages = driver.assigned_packages
                             .where.not(status: [:delivered, :cancelled, :return, :rescheduled])

    if pending_packages.any?
      count = pending_packages.count
      @errors << "⚠️ Tienes #{count} paquete#{count > 1 ? 's' : ''} sin finalizar. Marca cada paquete como entregado, cancelado o devuelto antes de cerrar la ruta."
      return false
    end

    true
  end

  # Calculate packages delivered during current route
  # Count packages delivered since route started_at
  def calculate_packages_delivered_in_current_route(route)
    return 0 unless route.started_at

    driver.assigned_packages
          .where(status: :delivered)
          .where('delivered_at >= ?', route.started_at)
          .count
  end

  def log_route_event(message)
    Rails.logger.info "[RouteManagement] Driver #{driver.id}: #{message}"
  end
end
