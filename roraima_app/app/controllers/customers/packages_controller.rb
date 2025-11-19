module Customers
  class PackagesController < ApplicationController
    before_action :set_package, only: [:show, :edit, :update, :destroy, :cancel]
    before_action :authorize_package, only: [:show, :edit, :update, :destroy]

    def index
      packages = policy_scope(Package).includes(:region, :commune)

      # Filtrar por estado si se especifica
      if params[:status].present? && Package.statuses.key?(params[:status])
        packages = packages.where(status: params[:status])
      end

      @pagy, @packages = pagy(packages.recent, items: 10)
      authorize Package
    end

    def show
    end

    def new
      @package = current_user.packages.build
      authorize @package
      @communes = []
    end

    def create
      @package = current_user.packages.build(package_params)
      authorize @package

      if @package.save
        redirect_to customers_package_path(@package), notice: 'Paquete creado exitosamente.'
      else
        @communes = @package.region_id ? Commune.where(region_id: @package.region_id).order(:name) : []
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @communes = @package.region ? @package.region.communes.order(:name) : []
    end

    def update
      if @package.update(package_params)
        redirect_to customers_package_path(@package), notice: 'Paquete actualizado exitosamente.'
      else
        @communes = @package.region_id ? Commune.where(region_id: @package.region_id).order(:name) : []
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @package.destroy
      redirect_to customers_packages_path, notice: 'Paquete eliminado exitosamente.'
    end

    def cancel
      authorize @package

      if @package.cancel!
        redirect_to customers_packages_path, notice: 'Paquete cancelado exitosamente.'
      else
        redirect_to customers_package_path(@package), alert: 'No se pudo cancelar el paquete.'
      end
    end

    private

    def set_package
      # Optimización: Usar includes para evitar N+1 queries en las vistas
      @package = Package.includes(:region, :commune).find(params[:id])
    end

    def authorize_package
      authorize @package
    end

    def package_params
      params.require(:package).permit(
        :customer_name,
        :company,
        :address,
        :description,
        :phone,
        :exchange,
        :pickup_date,
        :region_id,
        :commune_id
      )
    end
  end
end
