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

    unless driver.not_started? || driver.ready?
      @errors << "La ruta ya está en progreso o completada"
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
    true
  end

  # Calculate packages delivered during current route
  # Count packages delivered since route started_at
  def calculate_packages_delivered_in_current_route(route)
    return 0 unless route.started_at

    driver.assigned_packages
          .where(status: [:delivered, :picked_up])
          .where('delivered_at >= ?', route.started_at)
          .count
  end

  def log_route_event(message)
    Rails.logger.info "[RouteManagement] Driver #{driver.id}: #{message}"
  end
end
