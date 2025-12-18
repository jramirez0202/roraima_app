# Servicio para manejar transiciones de estado de paquetes
# Encapsula lógica de negocio y validaciones
class PackageStatusService
  attr_reader :package, :user, :errors

  def initialize(package, user)
    @package = package
    @user = user
    @errors = []
  end

  # Cambia el estado del paquete con validaciones
  def change_status(new_status, reason: nil, location: nil, override: false, **additional_params)
    new_status_sym = new_status.to_sym

    # Validaciones previas
    return false unless validate_transition(new_status_sym, override)
    # Solo validar requisitos si NO hay override (admin puede saltarse requisitos)
    return false unless override || validate_requirements(new_status_sym, additional_params)

    # Ejecutar transición
    begin
      package.transaction do
        # Aplicar parámetros adicionales si es necesario
        apply_additional_params(new_status_sym, additional_params)

        # Ejecutar transición
        package.transition_to!(
          new_status_sym,
          user: user,
          reason: reason,
          location: location,
          override: override
        )

        # Acciones post-transición
        after_transition_actions(new_status_sym)
      end

      true
    rescue StandardError => e
      @errors << e.message
      false
    end
  end

  # Asigna un courier al paquete
  def assign_courier(courier_id)
    courier = User.find_by(id: courier_id)

    unless courier
      @errors << "Courier no encontrado"
      return false
    end

    # Validar que el courier sea un Driver
    unless courier.driver?
      @errors << "El usuario no es un conductor válido"
      return false
    end

    # Validar que el courier esté activo
    unless courier.active?
      @errors << "No se puede asignar un conductor inactivo"
      return false
    end

    # Actualizar con campos de auditoría
    package.update(
      assigned_courier_id: courier_id,
      assigned_at: Time.current,
      assigned_by_id: @user.id
    )
  end

  # Marca como reprogramado con nueva fecha
  def reprogram(new_date, motive)
    unless new_date.present? && motive.present?
      @errors << "Fecha y motivo son requeridos para reprogramar"
      return false
    end

    change_status(
      :rescheduled,
      reason: motive,
      reprogram_date: new_date,
      motive: motive
    )
  end

  # Marca como entregado con prueba
  def mark_as_delivered(proof: nil, location: nil)
    unless proof.present?
      @errors << "Prueba de entrega (firma/foto) es requerida"
      return false
    end

    change_status(
      :delivered,
      reason: "Entrega exitosa",
      location: location,
      proof: proof
    )
  end

  # Marca como devolucion
  def mark_as_devolucion(reason:)
    unless reason.present?
      @errors << "Motivo de devolución es requerido"
      return false
    end

    change_status(
      :return,
      reason: reason
    )
  end

  # Registra un intento de entrega fallido
  def register_failed_attempt(reason:, reprogram_date: nil)
    package.increment_attempts!

    if package.attempts_count >= 3 && reprogram_date.nil?
      # Después de 3 intentos sin fecha de reprogramación, marcar para devolución
      mark_as_devolucion(reason: "Máximo de intentos alcanzado: #{reason}")
    elsif reprogram_date.present?
      reprogram(reprogram_date, reason)
    else
      @errors << "Se requiere fecha de reprogramación o marcarlo para devolución"
      false
    end
  end

  private

  # Valida si la transición es permitida
  def validate_transition(new_status, override)
    # SEGURIDAD: Solo admins pueden usar override
    if override && !user.admin?
      @errors << "Solo administradores pueden forzar transiciones con override"
      return false
    end

    unless package.can_transition_to?(new_status, override: override)
      current = package.status
      current_text = translate_status(current)
      new_status_text = translate_status(new_status)
      @errors << "Transición no permitida: #{current_text} → #{new_status_text}"
      return false
    end

    true
  end

  # Validates specific requirements according to destination status
  def validate_requirements(new_status, params)
    case new_status
    when :in_transit
      unless package.assigned_courier_id.present?
        @errors << "Debe asignar un courier antes de marcar como 'en camino'"
        return false
      end

    when :delivered
      unless params[:proof].present?
        status_text = translate_status(new_status)
        @errors << "Se requiere prueba (firma/foto/documento) para marcar como #{status_text}"
        return false
      end

    when :rescheduled
      unless params[:motive].present? || params[:reason].present?
        @errors << "Se requiere un motivo para reprogramar"
        return false
      end

    when :return
      # Return always requires reason (already validated in change_status)
    end

    true
  end

  # Applies additional parameters to the package
  def apply_additional_params(new_status, params)
    case new_status
    when :rescheduled
      package.reprogramed_to = params[:reprogram_date]
      package.reprogram_motive = params[:motive]

    when :delivered
      package.proof = params[:proof] if params[:proof].present?

    when :cancelled
      package.cancellation_reason = params[:reason] if params[:reason].present?
    end
  end

  # Actions executed after a successful transition
  def after_transition_actions(new_status)
    case new_status
    when :delivered
      # TODO: Send delivery notification to customer
      # TODO: Send notification to sender
      Rails.logger.info "Paquete #{package.tracking_code} marcado como #{new_status}"

      # Auto-complete route if all packages delivered
      if package.assigned_courier.driver? && package.assigned_courier.on_route?
        RouteManagementService.new(package.assigned_courier).auto_complete_if_finished
      end

    when :cancelled
      # TODO: Send cancellation notification
      Rails.logger.info "Paquete #{package.tracking_code} cancelado"

    when :rescheduled
      # TODO: Send rescheduling notification with new date
      Rails.logger.info "Paquete #{package.tracking_code} reprogramado para #{package.reprogramed_to}"

    when :return
      # TODO: Start return process, notify sender
      Rails.logger.info "Paquete #{package.tracking_code} marcado para devolución"
    end
  end

  # Traduce el estado del paquete a español
  # Reutiliza la misma lógica que el helper PackagesHelper#status_text
  def translate_status(status)
    status_sym = status.is_a?(String) ? status.to_sym : status

    case status_sym
    when :pending_pickup
      "Pendiente Retiro"
    when :in_warehouse
      "Bodega"
    when :in_transit
      "En Camino"
    when :rescheduled
      "Reprogramado"
    when :delivered
      "Entregado"
    when :return
      "Devolución"
    when :cancelled
      "Cancelado"
    else
      status.to_s.humanize
    end
  end
end
