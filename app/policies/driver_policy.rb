# frozen_string_literal: true

class DriverPolicy < ApplicationPolicy
  # Solo admin puede gestionar drivers
  def index?
    user.admin?
  end

  def show?
    user.admin? || record.id == user.id
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || record.id == user.id
  end

  def destroy?
    user.admin? && record.id != user.id
  end

  # Route management authorization
  def mark_ready_for_route?
    user.admin?
  end

  def toggle_ready?
    user.admin?
  end

  def start_route?
    user.driver? && record.id == user.id
  end

  def complete_route?
    user.admin? || (user.driver? && record.id == user.id)
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.driver?
        scope.where(id: user.id)
      else
        scope.none
      end
    end
  end
end
