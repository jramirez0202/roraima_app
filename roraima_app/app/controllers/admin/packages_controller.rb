class Admin::PackagesController < Admin::BaseController
  before_action :set_package, only: [:show, :edit, :update, :destroy, :change_status, :assign_courier, :status_history]
  before_action :authorize_package, only: [:show, :edit, :update, :destroy]
  before_action :load_users, only: [:new, :create, :edit, :update]
  before_action :load_couriers, only: [:index, :show, :assign_courier]

  def index
    packages = policy_scope(Package).includes(:user, :region, :commune, :assigned_courier)

    # Optimization: Calculate status counts in a single query
    # Uses index_packages_on_status
    status_counts = Package.group(:status).count
    @total_count = Package.count

    # Counts by each status
    @pending_pickup_count = status_counts[0] || 0
    @in_warehouse_count = status_counts[1] || 0
    @in_transit_count = status_counts[2] || 0
    @rescheduled_count = status_counts[3] || 0
    @delivered_count = status_counts[4] || 0
    @picked_up_count = status_counts[5] || 0
    @return_count = status_counts[6] || 0
    @cancelled_count = status_counts[7] || 0

    # Grouped counts
    @in_progress_count = @pending_pickup_count + @in_warehouse_count + @in_transit_count
    @needs_attention_count = @rescheduled_count + @return_count
    @completed_count = @delivered_count + @picked_up_count + @cancelled_count

    # Filtrar por estado si se especifica
    if params[:status].present? && Package.statuses.key?(params[:status])
      packages = packages.where(status: params[:status])
    end

    # Filtrar por courier asignado
    if params[:courier_id].present?
      packages = packages.where(assigned_courier_id: params[:courier_id])
    end

    @pagy, @packages = pagy(packages.order(created_at: :desc), items: 20)
    authorize Package
  end

  def show
  end

  def new
    @package = Package.new
    @package.region_id = metropolitan_region.id
    authorize @package
    @communes = metropolitan_region.communes.order(:name)
  end

  def create
    @package = Package.new(package_params)
    @package.user_id = current_user.id if @package.user_id.blank?
    @package.region_id = metropolitan_region.id
    authorize @package

    if @package.save
      redirect_to admin_packages_path, notice: 'Paquete creado exitosamente'
    else
      @communes = metropolitan_region.communes.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @communes = metropolitan_region.communes.order(:name)
  end

  def update
    @package.assign_attributes(package_params)
    @package.region_id = metropolitan_region.id

    if @package.save
      redirect_to admin_packages_path, notice: 'Paquete actualizado'
    else
      @communes = metropolitan_region.communes.order(:name)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @package.destroy
    redirect_to admin_packages_path, notice: 'Paquete eliminado exitosamente.'
  end

  def generate_labels
  # Preload usuarios con sus logos y comunas para evitar N+1
  @packages = Package
                .where(id: params[:package_ids])
                .includes(:commune, user: { company_logo_attachment: :blob })
  authorize Package

  # Validar que todos tengan la información necesaria
  invalid_packages = @packages.reject(&:ready_for_label?)

  if invalid_packages.any?
    error_message = "Algunos paquetes no tienen toda la información necesaria (fecha de entrega, nombre, dirección, teléfono o comuna)"
    respond_to do |format|
      format.html do
        flash[:alert] = error_message
        redirect_to admin_packages_path
      end
      format.pdf { render plain: error_message, status: :unprocessable_entity }
      format.any { render plain: error_message, status: :unprocessable_entity }
    end
    return
  end

  # Generar PDF pasando las instancias ya preload
  pdf = LabelGeneratorService.new(@packages).generate

  send_data pdf.render,
            filename: "etiquetas_#{Time.current.strftime('%Y%m%d_%H%M%S')}.pdf",
            type: 'application/pdf',
            disposition: 'inline'
end


  # Cambia el estado del paquete
  def change_status
    authorize @package, :change_status?

    new_status = params[:new_status]
    reason = params[:reason]
    location = params[:location]
    override = params[:override] == 'true' && policy(@package).override_transition?

    # Parámetros adicionales según el tipo de cambio
    additional_params = {}
    additional_params[:proof] = params[:proof] if params[:proof].present?
    additional_params[:reprogram_date] = params[:reprogram_date] if params[:reprogram_date].present?
    additional_params[:motive] = params[:motive] if params[:motive].present?

    service = PackageStatusService.new(@package, current_user)

    if service.change_status(new_status, reason: reason, location: location, override: override, **additional_params)
      redirect_to admin_package_path(@package), notice: "Estado cambiado a #{new_status} exitosamente"
    else
      redirect_to admin_package_path(@package), alert: "Error al cambiar estado: #{service.errors.join(', ')}"
    end
  end

  # Asigna un courier al paquete
  def assign_courier
    authorize @package, :assign_courier?

    courier_id = params[:courier_id]
    service = PackageStatusService.new(@package, current_user)

    if service.assign_courier(courier_id)
      redirect_to admin_package_path(@package), notice: 'Courier asignado exitosamente'
    else
      redirect_to admin_package_path(@package), alert: "Error al asignar courier: #{service.errors.join(', ')}"
    end
  end

  # Muestra el historial completo de cambios de estado
  def status_history
    authorize @package, :view_status_history?
    @history = @package.status_history || []
  end

  private

  def set_package
    # Optimización: Usar includes para evitar N+1 queries en las vistas
    @package = Package.includes(:region, :commune, :user).find(params[:id])
  end

  def authorize_package
    authorize @package
  end

  def load_users
    # Optimización: Cargar usuarios una sola vez con memoización
    @users ||= User.all.order(:email)
  end

  def load_couriers
    # Cargar solo usuarios que pueden ser couriers (admins y couriers)
    @couriers ||= User.all.order(:email)
  end

  def package_params
    params.require(:package).permit(
      :customer_name, :company, :address, :description, :user_id,
      :phone, :exchange, :loading_date, :commune_id, :amount
    )
  end

  def metropolitan_region
    @metropolitan_region ||= Region.find_by(name: "Región Metropolitana")
  end
end