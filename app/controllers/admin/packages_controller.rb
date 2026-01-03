class Admin::PackagesController < Admin::BaseController
  include FilterablePackages

  before_action :set_package, only: [:show, :edit, :update, :destroy, :change_status, :assign_courier, :status_history]
  before_action :authorize_package, only: [:show, :edit, :update, :destroy]
  before_action :load_users, only: [:new, :create, :edit, :update]
  before_action :load_couriers, only: [:index, :show, :assign_courier]

  def index
    # packages = policy_scope(Package).includes(:user, :region, :commune, :assigned_courier)

    packages = policy_scope(Package).includes(:region, :commune, assigned_courier: :assigned_zone,user: { company_logo_attachment: :blob })

    # Cargar drivers activos para el dropdown de asignación individual
    @drivers = Driver.active.includes(:assigned_zone).order(:email)

    # === APLICAR FILTRO DE FECHA PRIMERO (para counts correctos en tabs) ===
    # IMPORTANTE: Si busca por tracking, NO aplicar filtro de fecha por defecto
    searching_by_tracking = filter_params[:tracking_query].present?

    # Determinar rango de fecha según params
    if filter_params[:date_from].present? || filter_params[:date_to].present?
      # Usuario especificó fechas explícitamente
      date_from = parse_date(filter_params[:date_from])
      date_to = parse_date(filter_params[:date_to])

      # Si solo especifica "Desde" sin "Hasta", usar HOY como fecha final
      date_to ||= Date.current if date_from.present?

      # Si solo especifica "Hasta" sin "Desde", usar HOY como fecha inicial
      date_from ||= Date.current if date_to.present?

      packages_with_date = packages.loading_date_between(date_from, date_to)
    elsif !searching_by_tracking
      # Por defecto: solo el día actual (solo si NO busca por tracking)
      date_from = Date.current
      date_to = Date.current
      packages_with_date = packages.loading_date_between(date_from, date_to)
    else
      # Si busca por tracking sin fechas explícitas, NO filtrar por fecha
      packages_with_date = packages
    end

    # Status counts (respetando filtro de fecha)
    status_counts = packages_with_date.group(:status).count
    @total_count = packages_with_date.count
    @pending_pickup_count = status_counts["pending_pickup"] || 0
    @in_warehouse_count = status_counts["in_warehouse"] || 0
    @in_transit_count = status_counts["in_transit"] || 0
    @rescheduled_count = status_counts["rescheduled"] || 0
    @delivered_count = status_counts["delivered"] || 0
    @return_count = status_counts["return"] || 0
    @cancelled_count = status_counts["cancelled"] || 0

    # Contador de reprogramados persistentes (sin filtro de fecha - para resumen global)
    @persistent_rescheduled_count = Package.where(status: :rescheduled).count

    # Exponer variables de fecha para la vista
    @date_from = date_from
    @date_to = date_to

    # === APLICAR TODOS LOS FILTROS (incluyendo estado, comuna, driver) ===
    packages = apply_package_filters(packages)

    # === DATOS PARA FILTROS ===
    # Solo comunas de Región Metropolitana
    @communes = metropolitan_region&.communes&.order(:name) || Commune.none
    @couriers = Driver.active.order(:name)
    @active_filters = active_filters
    @active_filters_count = active_filters_count
    @filtered_count = packages.count

    # Ordenar según si hay filtro de fecha
    # Si hay filtro de fecha, ordenar por loading_date DESC (más recientes primero)
    # Si no hay filtro, ordenar por created_at DESC (más recientes primero)
    if filter_params[:date_from].present? || filter_params[:date_to].present?
      @pagy, @packages = pagy(packages.order(loading_date: :desc, created_at: :desc), items: 20)
    else
      @pagy, @packages = pagy(packages.order(created_at: :desc), items: 20)
    end
    authorize Package

    # Preservar parámetros de filtro para links a show
    @filter_params = @active_filters
  end

  def show
    # Limpiar fotos huérfanas (fotos que no corresponden al estado actual)
    # Esto puede suceder si una transacción falló pero las fotos quedaron adjuntas
    if @package.proof_photos.attached? && !@package.delivered?
      @package.proof_photos.purge
    end

    if @package.reschedule_photos.attached? && !@package.rescheduled?
      @package.reschedule_photos.purge
    end

    if @package.cancelled_photos.attached? && !@package.cancelled?
      @package.cancelled_photos.purge
    end

    # Preservar parámetros de filtro para el botón "Volver"
    @filter_params = {
      status: params[:status],
      commune_search: params[:commune_search],
      commune_ids: params[:commune_ids],
      courier_search: params[:courier_search],
      courier_ids: params[:courier_ids],
      tracking_query: params[:tracking_query],
      date_from: params[:date_from],
      date_to: params[:date_to]
    }.compact
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
    @package.sender_email ||= current_user.email
    @package.company_name ||= @package.user&.company
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

    # Preservar parámetros de filtro para el botón "Volver"
    @filter_params = {
      status: params[:status],
      commune_search: params[:commune_search],
      commune_ids: params[:commune_ids],
      courier_search: params[:courier_search],
      courier_ids: params[:courier_ids],
      tracking_query: params[:tracking_query],
      date_from: params[:date_from],
      date_to: params[:date_to]
    }.compact
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
    # DESHABILITADO: Eliminación de paquetes desactivada por seguridad
    # Los paquetes no deben eliminarse, solo cambiar su estado a "cancelled"
    redirect_to admin_packages_path, alert: 'La eliminación de paquetes está deshabilitada. Use cambio de estado a "Cancelado" en su lugar.'
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

    # Manejar cambio de driver si se proporciona
    if params[:courier_id].present?
      new_courier = User.find_by(id: params[:courier_id])

      if new_courier
        # Registrar el cambio de driver en el historial si había uno anterior
        if @package.assigned_courier_id.present? && @package.assigned_courier_id != new_courier.id
          previous_courier = @package.assigned_courier
          @package.add_to_history(
            status: @package.status,
            user_id: current_user.id,
            reason: "Driver cambiado: #{previous_courier.email} → #{new_courier.email}",
            location: location
          )
          @package.save! # Guardar el historial
        end

        # Asignar el nuevo driver con auditoría
        @package.update(
          assigned_courier_id: new_courier.id,
          assigned_at: Time.current,
          assigned_by_id: current_user.id
        )
      end
    end

    # Adjuntar fotos de evidencia (delivered) si se proporcionaron
    if new_status == 'delivered' && params[:proof_photos].present?
      # Validar límite de 4 fotos
      photos_to_attach = params[:proof_photos].is_a?(Array) ? params[:proof_photos] : [params[:proof_photos]]

      if photos_to_attach.size > 4
        redirect_to admin_package_path(@package), alert: 'Máximo 4 fotos permitidas'
        return
      end

      # Adjuntar todas las fotos (Active Storage las agrega, no las reemplaza)
      photos_to_attach.each do |photo|
        @package.proof_photos.attach(photo)
      end
    end

    # Parámetros adicionales según el tipo de cambio
    additional_params = {}
    additional_params[:proof] = @package.proof_photos.attached? ? 'attached' : nil
    additional_params[:reprogram_date] = params[:reprogram_date] if params[:reprogram_date].present?
    additional_params[:motive] = params[:motive] if params[:motive].present?

    service = PackageStatusService.new(@package, current_user)

    if service.change_status(new_status, reason: reason, location: location, override: override, **additional_params)
      # Adjuntar fotos de reprogramación si se proporcionaron
      if new_status == 'rescheduled' && params[:reschedule_photos].present?
        params[:reschedule_photos].each do |photo|
          @package.reschedule_photos.attach(photo)
        end
      end

      redirect_to admin_package_path(@package), notice: "Estado cambiado a #{new_status} exitosamente"
    else
      redirect_to admin_package_path(@package), alert: "Error al cambiar estado: #{service.errors.join(', ')}"
    end
  end

  # Cambia el estado de múltiples paquetes a la vez
  def bulk_status_change
    authorize Package, :bulk_update?

    package_ids = params[:package_ids] || []
    new_status = params[:new_status]
    reason = params[:reason] || 'Cambio masivo desde admin'

    if package_ids.empty?
      render json: { success: false, error: 'No se seleccionaron paquetes' }, status: :unprocessable_entity
      return
    end

    if new_status.blank?
      render json: { success: false, error: 'Debe especificar un estado' }, status: :unprocessable_entity
      return
    end

    # Cargar paquetes y validar permisos
    packages = Package.where(id: package_ids)
    successes = []
    errors = []

    packages.each do |package|
      # Verificar permisos individuales
      unless policy(package).change_status?
        errors << { tracking_code: package.tracking_code, error: 'Sin permisos' }
        next
      end

      # Verificar que no sea un estado terminal
      if package.terminal?
        errors << { tracking_code: package.tracking_code, error: 'Estado terminal, no se puede cambiar' }
        next
      end

      # Intentar cambiar el estado
      service = PackageStatusService.new(package, current_user)
      if service.change_status(new_status, reason: reason, override: true)
        successes << package.tracking_code
      else
        errors << { tracking_code: package.tracking_code, error: service.errors.join(', ') }
      end
    end

    render json: {
      success: true,
      total: packages.count,
      successful: successes.count,
      failed: errors.count,
      successes: successes,
      errors: errors
    }
  end

  # Asigna un courier al paquete
  def assign_courier
    authorize @package, :assign_courier?

    courier_id = params[:courier_id]
    service = PackageStatusService.new(@package, current_user)

    respond_to do |format|
      if service.assign_courier(courier_id)
        format.html { redirect_to admin_packages_path(status: params[:return_status]), notice: 'Conductor asignado exitosamente' }
        format.json { head :ok }
      else
        format.html { redirect_to admin_packages_path(status: params[:return_status]), alert: "Error al asignar conductor: #{service.errors.join(', ')}" }
        format.json { render json: { errors: service.errors }, status: :unprocessable_entity }
      end
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
    @package = Package.includes(:region,:commune,assigned_courier: :assigned_zone,user: { company_logo_attachment: :blob }).find(params[:id])
  end

  def authorize_package
    authorize @package
  end

  def load_users
    # Cargar solo usuarios customers activos (excluyendo Drivers, Admins e inactivos)
    @users ||= User.where(type: nil).where(admin: false).where(active: true).order(:email)
  end

  def load_couriers
    # Cargar solo drivers (usuarios con type = 'Driver')
    @couriers ||= Driver.all.order(:email)
  end

  def package_params
    params.require(:package).permit(
      :customer_name, :sender_email, :company_name, :address, :description, :user_id,
      :phone, :exchange, :loading_date, :commune_id, :amount
    )
  end

  def metropolitan_region
    @metropolitan_region ||= Region.find_by(name: "Región Metropolitana")
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError, TypeError
    nil
  end
end