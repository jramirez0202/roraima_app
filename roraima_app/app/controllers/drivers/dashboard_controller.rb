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
        total_assigned: current_driver.visible_packages.where(assigned_at: Date.current.all_day).count
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

    def complete_route
      authorize current_driver, :complete_route?

      notes = params[:notes].to_s.strip.presence

      service = RouteManagementService.new(current_driver)

      if service.complete_route(notes: notes)
        # Responder con Turbo Stream para actualizar navbar
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.remove("route_actions"),
              turbo_stream.update("flash-container", partial: "shared/flash", locals: {
                notice: "¡Ruta finalizada con éxito! Descansa bien."
              })
            ]
          end
          format.html { redirect_to drivers_root_path, notice: "¡Ruta finalizada con éxito! Descansa bien." }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update("flash-container", partial: "shared/flash", locals: {
              alert: "No se pudo finalizar la ruta: #{service.errors.join(', ')}"
            })
          end
          format.html { redirect_to drivers_root_path, alert: "No se pudo finalizar la ruta: #{service.errors.join(', ')}" }
        end
      end
    end
  end
end
