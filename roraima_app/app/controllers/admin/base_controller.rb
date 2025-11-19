module Admin
  class BaseController < ApplicationController
    before_action :check_admin

    private

    def check_admin
      unless current_user&.admin?
        # Redirigir a customers dashboard si es customer, o root si no hay usuario
        redirect_path = current_user&.customer? ? customers_dashboard_path : root_path
        redirect_to redirect_path, alert: 'No tienes permiso para acceder a esta sección.'
      end
    end
  end
end