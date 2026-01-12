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
  def assign_courier(courier_id, force_reassign: false)
    # CASO 1: Desasignación (courier_id vacío o nil)
    if courier_id.blank?
      # Si el paquete está en in_transit, usar transacción para asegurar atomicidad
      # (cambiar estado PRIMERO, luego desasignar driver)
      if package.status == 'in_transit'
        result = false

        ActiveRecord::Base.transaction do
          # 1. Cambiar a in_warehouse PRIMERO
          unless package.transition_to!(
            :in_warehouse,
            user: @user,
            reason: "Desasignación automática por admin",
            override: true
          )
            @errors << "No se pudo cambiar el paquete a Bodega"
            raise ActiveRecord::Rollback
          end

          # 2. Solo SI el cambio de estado fue exitoso, desasignar el driver
          unless package.update(
            assigned_courier_id: nil,
            assigned_at: nil,
            assigned_by_id: @user.id
          )
            @errors << "No se pudo desasignar el conductor"
            raise ActiveRecord::Rollback
          end

          Rails.logger.info "Paquete #{package.tracking_code} desasignado y regresado a in_warehouse por #{@user.email}"
          result = true
        end

        return result
      else
        # Si NO está en in_transit, solo desasignar (sin cambio de estado)
        result = package.update(
          assigned_courier_id: nil,
          assigned_at: nil,
          assigned_by_id: @user.id
        )

        Rails.logger.info "Paquete #{package.tracking_code} desasignado por #{@user.email}"
        return result
      end
    end

    # CASO 2: Asignación a un conductor
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

    # ========================================
    # VALIDACIONES CRÍTICAS DE SEGURIDAD
    # ========================================

    # VALIDACIÓN 1: SOLO se pueden asignar paquetes en BODEGA
    unless package.status == 'in_warehouse'
      @errors << "Solo se pueden asignar paquetes en estado 'Bodega'. Estado actual: #{package.status_i18n}"
      return false
    end

    # VALIDACIÓN 2: Prevenir reasignación de paquetes ya asignados
    if package.assigned_courier_id.present? && package.assigned_courier_id != courier_id.to_i
      # El paquete ya está asignado a OTRO driver
      previous_driver = User.find_by(id: package.assigned_courier_id)
      previous_driver_name = previous_driver&.name || previous_driver&.email || "Driver ID #{package.assigned_courier_id}"

      # Solo admin puede forzar reasignación
      if force_reassign && @user.admin?
        Rails.logger.warn "[REASIGNACIÓN FORZADA] Admin #{@user.email} reasigna #{package.tracking_code} de #{previous_driver_name} a #{courier.name || courier.email}"
      else
        @errors << "El paquete ya está asignado a #{previous_driver_name}. No se puede reasignar sin autorización admin."
        return false
      end
    end

    # CRÍTICO: Validar que el driver NO tenga una ruta activa de otro día
    if courier.on_route?
      # Buscar CUALQUIER ruta activa de otro día (no solo la primera)
      old_active_route = courier.routes.active_routes
                                .where.not('DATE(started_at) = ?', Date.current)
                                .order(started_at: :asc)
                                .first

      if old_active_route
        @errors << "⚠️ #{courier.name} tiene una ruta abierta desde el #{old_active_route.started_at.strftime('%d/%m/%Y')}. Debe cerrar esa ruta antes de asignar nuevos paquetes."
        return false
      end
    end

    # CRÍTICO: Usar transacción para asegurar atomicidad
    # Si falla el cambio de estado, la asignación se revierte automáticamente
    result = false

    ActiveRecord::Base.transaction do
      # 1. Cambiar a in_transit PRIMERO
      assign_reason = if @user.admin?
                        "Asignación automática por admin"
                      elsif @user.driver?
                        "Asignación por escaneo del driver"
                      else
                        "Asignación automática"
                      end

      # Intentar cambiar a in_transit
      unless package.transition_to!(
        :in_transit,
        user: @user,
        reason: assign_reason,
        override: true
      )
        @errors << "No se pudo cambiar el paquete a estado En Camino"
        raise ActiveRecord::Rollback
      end

      # 2. Solo SI el cambio de estado fue exitoso, asignar el driver
      unless package.update(
        assigned_courier_id: courier_id,
        assigned_at: Time.current,
        assigned_by_id: @user.id
      )
        @errors << "No se pudo asignar el conductor"
        raise ActiveRecord::Rollback
      end

      Rails.logger.info "Paquete #{package.tracking_code} asignado a #{courier.name || courier.email} y cambiado a in_transit por #{@user.email}"
      result = true
    end

    result
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

  # Marca como entregado (con o sin fotos inmediatas)
  def mark_as_delivered(location: nil, with_photos: false)
    # Si tiene fotos adjuntas, delivery normal
    if package.proof_photos.attached? && package.proof_photos.count >= 1
      return change_status(
        :delivered,
        reason: "Entrega exitosa con evidencia fotográfica",
        location: location,
        proof: 'attached'
      )
    end

    # Si NO tiene fotos, marcar como pending_photos
    unless with_photos
      begin
        package.mark_delivered_pending_photos!(user: user, location: location)
        Rails.logger.info "📦 Package #{package.tracking_code} marked as delivered, pending photos"
        return true
      rescue StandardError => e
        @errors << e.message
        return false
      end
    end

    # Si with_photos es true pero no hay fotos, error
    @errors << "Debe adjuntar fotos antes de marcar como entregado"
    false
  rescue StandardError => e
    @errors << e.message
    false
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
  # El parámetro override ya fue validado en validate_transition
  def validate_requirements(new_status, params)
    # RESTRICCIÓN: Drivers deben tener ruta iniciada para cambiar estados
    if user.driver? && !user.on_route?
      @errors << "Debes iniciar tu ruta antes de cambiar estados de paquetes"
      return false
    end

    case new_status
    when :in_transit
      unless package.assigned_courier_id.present?
        @errors << "Debe asignar un courier antes de marcar como 'en camino'"
        return false
      end

    when :delivered
      # Solo validar si NO se permite pending_photos Y no hay fotos adjuntas
      unless params[:allow_pending_photos] || package.proof_photos.attached?
        status_text = translate_status(new_status)
        @errors << "Se requiere evidencia fotográfica para marcar como #{status_text}"
        return false
      end

      # Validar que exista el nombre del receptor
      # NOTA: Esta validación se hace aquí porque validate_requirements solo se ejecuta
      # cuando NO hay override (ver línea 19: return false unless override || validate_requirements)
      unless package.receiver_name.present?
        @errors << "Se requiere el nombre del receptor para marcar como entregado"
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

      # Aplicar datos del receptor DENTRO de la transacción
      # Esto asegura que si falla el cambio de estado, los datos del receptor tampoco se guardan
      if params[:receiver_name].present?
        package.receiver_name = params[:receiver_name]
        package.receiver_observations = params[:receiver_observations]
      end

    when :cancelled
      package.cancellation_reason = params[:reason] if params[:reason].present?
    end
  end

  # Actions executed after a successful transition
  def after_transition_actions(new_status)
    # PERFORMANCE: Limpiar fotos huérfanas ANTES de las acciones específicas
    # Esto previene que fotos de estados anteriores queden adjuntas
    cleanup_orphan_photos(new_status)

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

  # Limpia fotos que no corresponden al estado actual
  # Esto puede suceder si una transacción falló pero las fotos quedaron adjuntas
  def cleanup_orphan_photos(current_status)
    # Purgar proof_photos si NO está delivered
    if package.proof_photos.attached? && current_status != :delivered
      package.proof_photos.purge
    end

    # Purgar reschedule_photos si NO está rescheduled
    if package.reschedule_photos.attached? && current_status != :rescheduled
      package.reschedule_photos.purge
    end

    # Purgar cancelled_photos si NO está cancelled
    if package.cancelled_photos.attached? && current_status != :cancelled
      package.cancelled_photos.purge
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
