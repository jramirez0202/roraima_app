# frozen_string_literal: true

module Admin
  class DriversController < Admin::BaseController
    before_action :set_driver, only: [:show, :edit, :update, :destroy, :toggle_ready]
    before_action :authorize_driver, only: [:show, :edit, :update, :destroy, :toggle_ready]

    def index
      drivers = policy_scope(Driver)

      # Filtro por zona asignada
      if params[:zone_id].present?
        drivers = drivers.where(assigned_zone_id: params[:zone_id])
      end

      # Filtro por status (active/inactive)
      if params[:status].present?
        drivers = case params[:status]
                  when 'active' then drivers.active
                  when 'inactive' then drivers.inactive
                  else drivers
                  end
      end

      # Incluir zona para evitar N+1 queries
      @pagy, @drivers = pagy(drivers.includes(:assigned_zone).order(created_at: :desc), items: 25)
      @zones = Zone.active.order(:name) # Para filtros
      authorize Driver
    end

    def show
      # Cargar estadísticas para la vista
      @today_deliveries_count = @driver.today_deliveries.count
      @pending_deliveries_count = @driver.pending_deliveries.count
      @total_deliveries_count = @driver.visible_packages.count

      # Load last 3 routes for history component
      @last_routes = @driver.last_routes(limit: 3)
    end

    def new
      @driver = Driver.new(active: true)
      @zones = Zone.active.order(:name)
      authorize @driver
    end

    def create
      @driver = Driver.new(driver_params)
      @driver.role = :driver
      @driver.password = params[:driver][:password] if params[:driver][:password].present?

      authorize @driver

      if @driver.save
        redirect_to admin_drivers_path, notice: "Conductor creado exitosamente."
      else
        @zones = Zone.active.order(:name)
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @zones = Zone.active.order(:name)
    end

    def update
      filtered_params = driver_params
      filtered_params = filtered_params.except(:password, :password_confirmation) if params[:driver][:password].blank?

      if @driver.update(filtered_params)
        redirect_to admin_driver_path(@driver), notice: "Conductor actualizado exitosamente."
      else
        @zones = Zone.active.order(:name)
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @driver.destroy
      redirect_to admin_drivers_path, notice: 'Conductor eliminado exitosamente.'
    end

    def toggle_ready
      @driver.update!(ready_for_route: !@driver.ready_for_route?)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "driver_#{@driver.id}",
            partial: 'driver_row',
            locals: { driver: @driver }
          )
        end
        format.html { redirect_to admin_drivers_path, notice: "Estado de autorización actualizado." }
      end
    end

    def bulk_start_routes
      driver_ids = params[:driver_ids] || []

      if driver_ids.empty?
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.append('flash', partial: 'shared/flash', locals: { type: 'alert', message: 'No se seleccionó ningún conductor.' })
          end
          format.html { redirect_to admin_drivers_path, alert: 'No se seleccionó ningún conductor.' }
        end
        return
      end

      drivers = Driver.where(id: driver_ids).includes(:assigned_zone)
      @results = { success: [], failed: [], updated_drivers: [] }

      drivers.each do |driver|
        service = RouteManagementService.new(driver)
        if service.start_route
          driver.reload
          @results[:success] << driver.name || driver.email
          @results[:updated_drivers] << driver
        else
          @results[:failed] << { driver: driver, errors: service.errors }
        end
      end

      respond_to do |format|
        format.turbo_stream
        format.html do
          if @results[:failed].empty?
            redirect_to admin_drivers_path, notice: "Rutas iniciadas exitosamente para #{@results[:success].count} conductor(es)."
          else
            flash[:alert] = "#{@results[:success].count} ruta(s) iniciada(s). #{@results[:failed].count} error(es): #{@results[:failed].map { |f| "#{f[:driver].name}: #{f[:errors].join(', ')}" }.join(' | ')}"
            redirect_to admin_drivers_path
          end
        end
      end
    end

    # Búsqueda de drivers para autocomplete (usado en asignación de paquetes)
    # GET /admin/drivers/search?q=carlos
    def search
      authorize Driver, :index?

      query = params[:q].to_s.strip

      # Si el query está vacío, devolver los primeros 20 drivers activos
      if query.blank?
        drivers = Driver.active.limit(20).order(:name)
      else
        # Buscar por nombre o email (case insensitive)
        drivers = Driver.active
                        .where("name ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%")
                        .limit(20)
                        .order(:name)
      end

      # Incluir assigned_packages para evitar N+1
      drivers = drivers.includes(:assigned_packages)

      # Formatear respuesta JSON
      results = drivers.map do |driver|
        {
          id: driver.id,
          name: driver.name.presence || driver.email,
          email: driver.email,
          assigned_count: driver.assigned_packages.count,
          zone: driver.assigned_zone&.name
        }
      end

      render json: results
    end

    private

    def set_driver
      @driver = Driver.find(params[:id])
    end

    def authorize_driver
      authorize @driver
    end

    def driver_params
      params.require(:driver).permit(
        :name, :email, :password, :password_confirmation,
        :rut, :phone, :active,
        :vehicle_plate, :vehicle_model, :vehicle_capacity, :assigned_zone_id,
        :ready_for_route
      )
    end
  end
end
