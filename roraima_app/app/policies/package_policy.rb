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
    # Solo el dueño puede cancelar sus paquetes activos
    (user.admin? || record.user_id == user.id) && record.active?
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
