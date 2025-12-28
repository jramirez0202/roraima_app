module Admin
  class BaseController < ApplicationController
    before_action :check_admin

    private

    def check_admin
      unless current_user&.admin?
        # Redirigir según tipo de usuario
        redirect_path = if current_user.driver?
                          drivers_root_path
                        elsif current_user&.customer?
                          customers_dashboard_path
                        else
                          root_path
                        end
        redirect_to redirect_path, alert: 'No tienes permiso para acceder a esta sección.'
      end
    end
  end
end