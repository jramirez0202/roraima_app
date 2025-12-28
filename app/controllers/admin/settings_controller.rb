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
      params.require(:setting).permit(
        :require_driver_authorization,
        :customer_visible_pending_pickup,
        :customer_visible_in_warehouse,
        :customer_visible_in_transit,
        :customer_visible_rescheduled,
        :customer_visible_delivered,
        :customer_visible_return,
        :customer_visible_cancelled
      )
    end
  end
end
