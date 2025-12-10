# frozen_string_literal: true

class PackagePolicy < ApplicationPolicy
  def index?
    true # Todos los usuarios autenticados pueden ver la lista de paquetes
  end

  def show?
    user.admin? ||
    record.user_id == user.id ||
    (user.is_a?(Driver) && record.assigned_courier_id == user.id)
  end

  def create?
    user.admin? || user.customer?
    # Drivers NO pueden crear paquetes
  end

  def update?
    user.admin? || record.user_id == user.id
  end

  def destroy?
    user.admin? || record.user_id == user.id
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
    (user.is_a?(Driver) && record.assigned_courier_id == user.id)
  end

  def assign_courier?
    user.admin? # Solo admin puede asignar couriers
  end

  def bulk_update?
    user.admin? # Solo admin puede hacer cambios masivos
  end

  def override_transition?
    user.admin? # Solo admin puede forzar transiciones
  end

  def mark_as_delivered?
    # Admin or assigned driver can mark as delivered
    user.admin? ||
    (user.is_a?(Driver) && record.assigned_courier_id == user.id && record.in_transit?)
  end

  def mark_as_picked_up?
    # Admin can mark as picked up from warehouse
    user.admin? && record.in_warehouse?
  end

  def reprogram?
    # Admin or assigned driver can reschedule
    user.admin? ||
    (user.is_a?(Driver) && record.assigned_courier_id == user.id && record.in_transit?)
  end

  def mark_as_return?
    # Admin can initiate return
    # Driver can mark for return if in transit or rescheduled
    user.admin? ||
    (user.is_a?(Driver) && record.assigned_courier_id == user.id && (record.in_transit? || record.rescheduled?))
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
      elsif user.is_a?(Driver)
        # Drivers see all packages assigned to them (from pending_pickup onwards)
        scope.where(assigned_courier_id: user.id)
      else
        scope.none
      end
    end
  end
end

