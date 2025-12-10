# frozen_string_literal: true

module Drivers
  class DashboardController < BaseController
    def index
      @pending_packages = current_driver.pending_deliveries
                                        .includes(:region, :commune)
                                        .order(loading_date: :asc)

      @today_deliveries = current_driver.today_deliveries
                                        .includes(:region, :commune)

      @stats = {
        pending: current_driver.pending_deliveries.count,
        today: @today_deliveries.count,
        total_assigned: current_driver.visible_packages.count
      }
    end

    def start_route
      authorize current_driver, :start_route?

      service = RouteManagementService.new(current_driver)

      if service.start_route
        redirect_to drivers_root_path, notice: '¡Ruta iniciada con éxito! Buena suerte con las entregas.'
      else
        redirect_to drivers_root_path, alert: "No se pudo iniciar la ruta: #{service.errors.join(', ')}"
      end
    end
  end
end
