# frozen_string_literal: true

module Drivers
  class ProfilesController < BaseController
    def show
      @driver = current_driver

      # Parsear semana desde params (lunes de la semana)
      # Si no hay parámetro, usar semana actual
      week_param = params[:week].presence

      if week_param
        begin
          @current_week_start = Date.parse(week_param)
          # Asegurarse de que sea lunes
          @current_week_start = @current_week_start.beginning_of_week(:monday)
        rescue ArgumentError
          # Si el formato es inválido, usar semana actual
          @current_week_start = Date.current.beginning_of_week(:monday)
        end
      else
        @current_week_start = Date.current.beginning_of_week(:monday)
      end

      # Calcular fin de semana (domingo)
      @current_week_end = @driver.week_end_for(@current_week_start)

      # Obtener estadísticas semanales
      @weekly_stats = @driver.weekly_summary(@current_week_start)

      # Calcular semana anterior (restar 7 días al lunes actual)
      @previous_week_start = @current_week_start - 7.days

      # Calcular semana siguiente (solo si no estamos en semana actual)
      today_week_start = Date.current.beginning_of_week(:monday)
      @next_week_start = if @current_week_start < today_week_start
                           @current_week_start + 7.days
                         else
                           nil  # No mostrar "Siguiente" si ya estamos en semana actual
                         end

      # Flag para saber si estamos viendo la semana actual
      @is_current_week = (@current_week_start == today_week_start)
    end

    def edit
      @driver = current_driver
      @zones = Zone.active
    end

    def update
      @driver = current_driver

      if @driver.update(driver_params)
        redirect_to drivers_profile_path, notice: 'Perfil actualizado'
      else
        @zones = Zone.active
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def driver_params
      params.require(:driver).permit(
        :vehicle_plate, :vehicle_model, :vehicle_capacity,
        :assigned_zone_id, :phone
      )
    end
  end
end
