class Admin::PackagesController < Admin::BaseController
  before_action :set_package, only: [:show, :edit, :update, :destroy]
  before_action :authorize_package, only: [:show, :edit, :update, :destroy]
  before_action :load_users, only: [:new, :create, :edit, :update]

  def index
    packages = policy_scope(Package).includes(:user, :region, :commune)

    # Optimización: Calcular conteos por status en una sola query
    # Aprovecha el índice index_packages_on_status
    status_counts = Package.group(:status).count
    @total_count = Package.count
    @active_count = status_counts[0] || 0  # active = 0
    @cancelled_count = status_counts[1] || 0  # cancelled = 1

    # Filtrar por estado si se especifica
    if params[:status].present? && Package.statuses.key?(params[:status])
      packages = packages.where(status: params[:status])
    end

    @pagy, @packages = pagy(packages.order(created_at: :desc), items: 20)
    authorize Package
  end

  def show
  end

  def new
    @package = Package.new
    authorize @package
    @regions = Region.ordered
    @communes = []
  end

  def create
    @package = Package.new(package_params)
    @package.user_id = current_user.id if @package.user_id.blank?
    authorize @package

    if @package.save
      redirect_to admin_packages_path, notice: 'Paquete creado exitosamente'
    else
      @regions = Region.order(:name)
      @communes = @package.region_id ? Commune.where(region_id: @package.region_id).order(:name) : []
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @regions = Region.ordered
    @communes = @package.region ? @package.region.communes.ordered : []
  end

  def update
    if @package.update(package_params)
      redirect_to admin_packages_path, notice: 'Paquete actualizado'
    else
      @regions = Region.order(:name)
      @communes = @package.region_id ? Commune.where(region_id: @package.region_id).order(:name) : []

      # Debug removido - usar Rails.logger si es necesario
      Rails.logger.debug "Region ID: #{@package.region_id.inspect}"
      Rails.logger.debug "Comunas cargadas: #{@communes.count}"

      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @package.destroy
    redirect_to admin_packages_path, notice: 'Paquete eliminado exitosamente.'
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

  def package_params
    params.require(:package).permit(
      :customer_name, :company, :weight, :dimension_x, :dimension_y,
      :address, :description, :user_id, :phone, :exchange, :pickup_date,
      :region_id, :commune_id
    )
  end
end