# frozen_string_literal: true

module Admin
  class ZonesController < Admin::BaseController
    before_action :set_zone, only: [:show, :edit, :update, :destroy]
    before_action :authorize_zone, only: [:show, :edit, :update, :destroy]

    def index
      zones = policy_scope(Zone)

      # Filtro por región
      if params[:region_id].present?
        zones = zones.where(region_id: params[:region_id])
      end

      # Filtro por status (active/inactive)
      if params[:status].present?
        zones = case params[:status]
                when 'active' then zones.active
                when 'inactive' then zones.where(active: false)
                else zones
                end
      end

      @pagy, @zones = pagy(zones.includes(:region, :drivers).order(:name), items: 25)
      @regions = Region.order(:name) # Para filtros
      authorize Zone
    end

    def show
      # Cargar drivers asignados a esta zona
      @drivers = @zone.drivers.includes(:assigned_zone).order(:email)
      # Cargar comunas de esta zona
      @communes = Commune.where(id: @zone.communes).order(:name) if @zone.communes.present?
    end

    def new
      @zone = Zone.new(active: true)
      @regions = Region.order(:name)
      authorize @zone
    end

    def create
      @zone = Zone.new(zone_params)
      authorize @zone

      if @zone.save
        redirect_to admin_zones_path, notice: "Zona creada exitosamente."
      else
        @regions = Region.order(:name)
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @regions = Region.order(:name)
      # Cargar comunas de la región seleccionada
      @communes = @zone.region.communes.order(:name) if @zone.region.present?
    end

    def update
      if @zone.update(zone_params)
        redirect_to admin_zone_path(@zone), notice: "Zona actualizada exitosamente."
      else
        @regions = Region.order(:name)
        @communes = @zone.region.communes.order(:name) if @zone.region.present?
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @zone.destroy
      redirect_to admin_zones_path, notice: 'Zona eliminada exitosamente.'
    end

    # Endpoint AJAX para obtener comunas por región
    def communes_by_region
      region = Region.find(params[:region_id])
      communes = region.communes.order(:name)

      render json: communes.map { |c| { id: c.id, name: c.name } }
    end

    private

    def set_zone
      @zone = Zone.find(params[:id])
    end

    def authorize_zone
      authorize @zone
    end

    def zone_params
      params.require(:zone).permit(
        :name,
        :region_id,
        :active,
        communes: []
      )
    end
  end
end
