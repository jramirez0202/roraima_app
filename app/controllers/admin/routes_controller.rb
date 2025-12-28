# frozen_string_literal: true

module Admin
  class RoutesController < BaseController
    before_action :set_route, only: [:force_close]

    # GET /admin/routes/old_active
    # Muestra rutas activas de días anteriores
    def old_active
      @old_routes = Route.old_active_routes
                         .includes(:driver)
                         .order(started_at: :asc)

      authorize Route, :manage?
    end

    # POST /admin/routes/:id/force_close
    # Cierra forzadamente una ruta antigua
    def force_close
      authorize @route, :force_close?

      reason = params[:reason]&.strip

      result = RouteManagementService.force_close_route(@route, current_user, reason)

      if result[:success]
        redirect_to admin_old_active_routes_path,
                    notice: "Ruta cerrada exitosamente. Driver: #{@route.driver.name}"
      else
        redirect_to admin_old_active_routes_path,
                    alert: "Error: #{result[:errors].join(', ')}"
      end
    end

    private

    def set_route
      @route = Route.find(params[:id])
    end
  end
end
