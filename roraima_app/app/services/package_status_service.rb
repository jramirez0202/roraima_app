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
    return false unless validate_requirements(new_status_sym, additional_params)

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

    package.update(assigned_courier_id: courier_id)
  end

  # Marca como reprogramado con nueva fecha
  def reprogram(new_date, motive)
    unless new_date.present? && motive.present?
      @errors << "Fecha y motivo son requeridos para reprogramar"
      return false
    end

    change_status(
      :reprogramado,
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
      :entregado,
      reason: "Entrega exitosa",
      location: location,
      proof: proof
    )
  end

  # Marca como retirado con prueba
  def mark_as_retirado(proof: nil, location: nil)
    unless proof.present?
      @errors << "Prueba de retiro (documento) es requerida"
      return false
    end

    change_status(
      :retirado,
      reason: "Retirado por cliente",
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
      :devolucion,
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
    unless package.can_transition_to?(new_status, override: override)
      current = package.status
      @errors << "Transición no permitida: #{current} → #{new_status}"
      return false
    end

    true
  end

  # Valida requisitos específicos según el estado destino
  def validate_requirements(new_status, params)
    case new_status
    when :en_camino
      unless package.assigned_courier_id.present?
        @errors << "Debe asignar un courier antes de marcar como 'en camino'"
        return false
      end

    when :entregado, :retirado
      unless params[:proof].present?
        @errors << "Se requiere prueba (firma/foto/documento) para marcar como #{new_status}"
        return false
      end

    when :reprogramado
      unless params[:reprogram_date].present? && params[:motive].present?
        @errors << "Se requiere nueva fecha y motivo para reprogramar"
        return false
      end

    when :devolucion
      # Devolución siempre requiere motivo (ya validado en change_status)
    end

    true
  end

  # Aplica parámetros adicionales al paquete
  def apply_additional_params(new_status, params)
    case new_status
    when :reprogramado
      package.reprogramed_to = params[:reprogram_date]
      package.reprogram_motive = params[:motive]

    when :entregado, :retirado
      package.proof = params[:proof] if params[:proof].present?

    when :cancelado
      package.cancellation_reason = params[:reason] if params[:reason].present?
    end
  end

  # Acciones que se ejecutan después de una transición exitosa
  def after_transition_actions(new_status)
    case new_status
    when :entregado, :retirado
      # TODO: Enviar notificación de entrega al cliente
      # TODO: Enviar notificación al remitente
      Rails.logger.info "Paquete #{package.tracking_code} marcado como #{new_status}"

    when :cancelado
      # TODO: Enviar notificación de cancelación
      Rails.logger.info "Paquete #{package.tracking_code} cancelado"

    when :reprogramado
      # TODO: Enviar notificación de reprogramación con nueva fecha
      Rails.logger.info "Paquete #{package.tracking_code} reprogramado para #{package.reprogramed_to}"

    when :devolucion
      # TODO: Iniciar proceso de devolución, notificar al remitente
      Rails.logger.info "Paquete #{package.tracking_code} marcado para devolución"
    end
  end
end
