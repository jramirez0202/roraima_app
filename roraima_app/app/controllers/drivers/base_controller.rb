# frozen_string_literal: true

module Drivers
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_driver!

    layout 'drivers'

    private

    def ensure_driver!
      unless current_user.is_a?(Driver)
        redirect_to root_path, alert: 'Acceso solo para conductores'
      end
    end

    def current_driver
      current_user
    end
    helper_method :current_driver
  end
end
