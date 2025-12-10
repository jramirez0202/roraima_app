class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user, only: [:show, :edit, :update, :destroy]

  def index
    users = policy_scope(User)

    # Filtrar por role si se especifica
    if params[:role].present? && User.roles.key?(params[:role])
      users = users.where(role: params[:role])
    end

    # Filtrar por status (active/inactive)
    if params[:status].present?
      users = case params[:status]
              when 'active' then users.active
              when 'inactive' then users.inactive
              else users
              end
    end

    @pagy, @users = pagy(users.order(created_at: :desc), items: 25)
    authorize User
  end

  def show
  end

  def new
    @user = User.new
    authorize @user
  end

  def create
    # Prevenir creación de drivers desde este controlador
    if params[:user][:role] == 'driver'
      redirect_to new_admin_driver_path, alert: 'Los conductores deben crearse desde Gestión de Conductores'
      return
    end

    @user = User.new(user_params_for_role)
    @user.password = params[:user][:password] if params[:user][:password].present?

    authorize @user

    if @user.save
      role_name = @user.display_role
      redirect_to admin_users_path, notice: "#{role_name} creado exitosamente."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    user_params_filtered = user_params_for_role
    user_params_filtered = user_params_filtered.except(:password, :password_confirmation) if params[:user][:password].blank?

    if @user.update(user_params_filtered)
      role_name = @user.display_role
      redirect_to admin_users_path, notice: "#{role_name} actualizado exitosamente."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: 'Usuario eliminado exitosamente.'
  end

  private

  def set_user
    @user = User.find(params[:id])

    # Si es un Driver, redirigir a DriversController
    if @user.is_a?(Driver) && action_name != 'show'
      redirect_to edit_admin_driver_path(@user),
                  alert: 'Los conductores deben editarse desde Gestión de Conductores'
    end
  end

  def authorize_user
    authorize @user
  end

  def user_params
    params.require(:user).permit(
      :email, :password, :password_confirmation, :role,
      :rut, :phone, :company, :active, :delivery_charge
    )
  end

  # ⭐ Strong params condicionales por rol (mejora de seguridad)
  def user_params_for_role
    role = params[:user][:role]&.to_sym || @user&.role&.to_sym

    case role
    when :admin
      params.require(:user).permit(:email, :password, :password_confirmation, :role, :active)
    when :customer
      params.require(:user).permit(
        :email, :password, :password_confirmation, :role, :active,
        :rut, :phone, :company, :delivery_charge
      )
    when :driver
      params.require(:user).permit(
        :email, :password, :password_confirmation, :role, :active,
        :rut, :phone,
        :vehicle_plate, :vehicle_model, :vehicle_capacity, :assigned_zone_id
      )
    else
      params.require(:user).permit(:email, :password, :password_confirmation, :role)
    end
  end
end