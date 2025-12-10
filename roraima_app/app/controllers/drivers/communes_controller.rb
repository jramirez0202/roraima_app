# frozen_string_literal: true

module Drivers
  class CommunesController < BaseController
    def by_region
      @communes = Commune.where(region_id: params[:region_id]).order(:name)
      render json: @communes.map { |c| { id: c.id, name: c.name } }
    end
  end
end
