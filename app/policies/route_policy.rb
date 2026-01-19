# frozen_string_literal: true

class RoutePolicy < ApplicationPolicy
  def manage?
    user.admin?
  end

  def force_close?
    user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
