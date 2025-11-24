# frozen_string_literal: true

class PackagePolicy < ApplicationPolicy
  def index?
    true # Todos los usuarios autenticados pueden ver la lista de paquetes
  end

  def show?
    user.admin? || record.user_id == user.id
  end

  def create?
    true # Todos los usuarios autenticados pueden crear paquetes
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
    # Courier solo puede cambiar estado de paquetes asignados a él
    user.admin? || (user.id == record.assigned_courier_id)
  end

  def assign_courier?
    user.admin? # Solo admin puede asignar couriers
  end

  def override_transition?
    user.admin? # Solo admin puede forzar transiciones
  end

  def mark_as_entregado?
    # Admin o courier asignado pueden marcar como entregado
    user.admin? || (user.id == record.assigned_courier_id && record.en_camino?)
  end

  def mark_as_retirado?
    # Admin puede marcar como retirado desde bodega
    user.admin? && record.en_bodega?
  end

  def reprogram?
    # Admin o courier asignado pueden reprogramar
    user.admin? || (user.id == record.assigned_courier_id && record.en_camino?)
  end

  def mark_as_devolucion?
    # Admin puede iniciar devolución
    # Courier puede marcar para devolución si está en camino o reprogramado
    user.admin? || (user.id == record.assigned_courier_id && (record.en_camino? || record.reprogramado?))
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
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
