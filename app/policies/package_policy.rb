# frozen_string_literal: true

class PackagePolicy < ApplicationPolicy
  def index?
    true # Todos los usuarios autenticados pueden ver la lista de paquetes
  end

  def show?
    return true if user.admin?
    return true if record.user_id == user.id

    # Driver puede ver si actualmente está asignado
    return true if user.driver? && record.assigned_courier_id == user.id

    # Driver puede ver paquetes terminales que él entregó/canceló
    # Verificar en status_history si tiene assigned_courier_id = driver.id
    if user.driver? && record.terminal? && record.status_history.present?
      # Buscar en el historial si algún registro tiene assigned_courier_id del driver
      record.status_history.any? { |entry| entry['assigned_courier_id'] == user.id }
    else
      false
    end
  end

  def create?
    user.admin? || user.customer?
    # Drivers NO pueden crear paquetes
  end

  def update?
    # Admin puede editar siempre
    return true if user.admin?

    # Driver puede actualizar detalles del receptor de paquetes asignados
    return true if user.driver? && record.assigned_courier_id == user.id

    # Cliente solo puede editar si el paquete está en estado pending_pickup
    # Una vez que está en bodega o más allá, ya no puede modificarlo
    record.user_id == user.id && record.pending_pickup?
  end

  def destroy?
    # DESHABILITADO: Eliminación de paquetes desactivada por seguridad
    # Los paquetes no deben eliminarse, solo cambiar su estado a "cancelled"
    false
  end

  def cancel?
    # Only admin can cancel packages
    user.admin?
  end

  def generate_labels?
    true # Todos los usuarios autenticados pueden generar etiquetas de sus paquetes
  end

  # Permisos para cambios de estado
  def change_status?
    # Admin puede cambiar cualquier estado
    # Driver solo puede cambiar estado de paquetes asignados a él
    user.admin? ||
    (user.driver? && record.assigned_courier_id == user.id)
  end

  def assign_courier?
    user.admin? # Solo admin puede asignar couriers
  end

  def bulk_update?
    user.admin? # Solo admin puede hacer cambios masivos
  end

  def bulk_assign_driver?
    user.admin? # Solo admin puede asignar paquetes masivamente a drivers
  end

  def override_transition?
    user.admin? # Solo admin puede forzar transiciones
  end

  def mark_as_delivered?
    # Admin or assigned driver can mark as delivered
    user.admin? ||
    (user.driver? && record.assigned_courier_id == user.id && record.in_transit?)
  end

  def reprogram?
    # Admin or assigned driver can reschedule
    user.admin? ||
    (user.driver? && record.assigned_courier_id == user.id && record.in_transit?)
  end

  def mark_as_return?
    # Admin can initiate return
    # Driver can mark for return if in transit or rescheduled
    user.admin? ||
    (user.driver? && record.assigned_courier_id == user.id && (record.in_transit? || record.rescheduled?))
  end

  def view_status_history?
    # Admin puede ver historial completo
    # Dueño puede ver historial simplificado de su paquete
    user.admin? || record.user_id == user.id
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.customer?
        scope.where(user_id: user.id)
      elsif user.driver?
        # Drivers see:
        # 1. Active packages currently assigned to them (assigned_courier_id = driver.id)
        # 2. Terminal packages (delivered/cancelled) that were assigned to them
        #    (checking status_history because they're auto-unassigned)

        # Combine both conditions with OR
        scope.where(assigned_courier_id: user.id)
             .or(
               scope.where(status: [:delivered, :cancelled])
                    .where("status_history @> ?", [{ assigned_courier_id: user.id }].to_json)
             )
      else
        scope.none
      end
    end
  end
end

