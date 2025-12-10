# frozen_string_literal: true

module Admin
  class SettingsController < Admin::BaseController
    before_action :set_setting

    def show
      # Show current settings
    end

    def update
      if @setting.update(setting_params)
        redirect_to admin_settings_path, notice: "Configuración actualizada exitosamente."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_setting
      @setting = Setting.instance
    end

    def setting_params
      params.require(:setting).permit(:require_driver_authorization)
    end
  end
end
