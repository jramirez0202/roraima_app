# frozen_string_literal: true

module Drivers
  class ProfilesController < BaseController
    def show
      @driver = current_driver
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
