module Customers
  class PackagesController < ApplicationController
    include FilterablePackages

    before_action :set_package, only: [:show, :edit, :update, :destroy]
    before_action :authorize_package, only: [:show, :edit, :update, :destroy]

    def index
      packages = policy_scope(Package)
                   .customer_visible_statuses  # Filtra por estados visibles configurados en admin
                   .includes(:region, :commune, :assigned_courier)

      # Cargar drivers activos para el dropdown de asignación
      @drivers = Driver.active.includes(:assigned_zone).order(:email)

      # Aplicar filtros específicos para customers (usa loading_date)
      packages = apply_customer_filters(packages)

      # Datos para filtros
      @active_filters = active_filters
      @active_filters_count = active_filters_count
      @filtered_count = packages.count
      @total_count = policy_scope(Package).customer_visible_statuses.count

      # Ordenar por fecha de carga (más reciente primero)
      @pagy, @packages = pagy(packages.order(loading_date: :desc), items: 10)
      authorize Package
    end

    def show
    end

    def new
      @package = current_user.packages.build
      @package.region_id = metropolitan_region.id
      @package.sender_email = current_user.email
      @package.company_name = current_user.company
      authorize @package
      @communes = metropolitan_region.communes.order(:name)
    end

    def create
      @package = current_user.packages.build(package_params)
      @package.region_id = metropolitan_region.id
      @package.sender_email = current_user.email
      @package.company_name = current_user.company
      authorize @package

      if @package.save
        redirect_to customers_package_path(@package), notice: 'Paquete creado exitosamente.'
      else
        @communes = metropolitan_region.communes.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @communes = metropolitan_region.communes.order(:name)
    end

    def update
      @package.assign_attributes(package_params)
      @package.region_id = metropolitan_region.id
      @package.sender_email = current_user.email
      @package.company_name = current_user.company

      if @package.save
        redirect_to customers_package_path(@package), notice: 'Paquete actualizado exitosamente.'
      else
        @communes = metropolitan_region.communes.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @package.destroy
      redirect_to customers_packages_path, notice: 'Paquete eliminado exitosamente.'
    end

    def generate_labels
      @packages = Package.where(id: params[:package_ids])
      authorize Package

      # Validar que todos tengan la información necesaria
      invalid_packages = @packages.reject(&:ready_for_label?)

      if invalid_packages.any?
        error_message = "Algunos paquetes no tienen toda la información necesaria (fecha de entrega, nombre, dirección, teléfono o comuna)"

        respond_to do |format|
          format.html do
            flash[:alert] = error_message
            redirect_to customers_packages_path
          end
          format.pdf do
            render plain: error_message, status: :unprocessable_entity
          end
          format.any do
            render plain: error_message, status: :unprocessable_entity
          end
        end
        return
      end

      # Generar PDF
      pdf = LabelGeneratorService.new(@packages).generate

      send_data pdf.render,
                filename: "etiquetas_#{Time.current.strftime('%Y%m%d_%H%M%S')}.pdf",
                type: 'application/pdf',
                disposition: 'inline'
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
        :address,
        :description,
        :phone,
        :exchange,
        :commune_id,
        :amount
      )
    end

    def metropolitan_region
      @metropolitan_region ||= Region.find_by(name: "Región Metropolitana")
    end

    # Filtros específicos para customers: usa loading_date (fecha de carga)
    # en lugar de activity_date_between que es más complejo
    def apply_customer_filters(base_scope)
      scope = base_scope

      # Filtro por estado
      if filter_params[:status].present? && Package.statuses.key?(filter_params[:status])
        scope = scope.where(status: filter_params[:status])
      end

      # Búsqueda por tracking code
      searching_by_tracking = filter_params[:tracking_query].present?
      if searching_by_tracking
        scope = scope.search_by_tracking(filter_params[:tracking_query].strip)
      end

      # Rango de fechas por LOADING_DATE (fecha de carga del cliente)
      if filter_params[:date_from].present? || filter_params[:date_to].present?
        date_from = parse_date(filter_params[:date_from])
        date_to = parse_date(filter_params[:date_to])

        # Si solo especifica "Desde" sin "Hasta", usar la misma fecha
        date_to ||= date_from if date_from.present?

        # Si solo especifica "Hasta" sin "Desde", usar la misma fecha
        date_from ||= date_to if date_to.present?

        # Validar que date_from <= date_to, si no, intercambiar
        if date_from && date_to && date_from > date_to
          date_from, date_to = date_to, date_from
        end

        scope = scope.loading_date_between(date_from, date_to)
      elsif !searching_by_tracking
        # Por defecto: mostrar paquetes del día actual si no busca por tracking
        scope = scope.where(loading_date: Date.current)
      end

      scope
    end
  end
end
