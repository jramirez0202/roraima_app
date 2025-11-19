class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @users = pagy(policy_scope(User).order(created_at: :desc), items: 25)
    authorize User
  end

  def show
  end

  def new
    @user = User.new
    authorize @user
  end

  def create
    @user = User.new(user_params)
    @user.password = params[:user][:password] if params[:user][:password].present?

    # Convertir el parámetro admin legacy a role enum
    if params[:user][:admin].present?
      @user.role = params[:user][:admin].to_s == 'true' ? :admin : :customer
    end

    authorize @user

    if @user.save
      redirect_to admin_users_path, notice: 'Usuario creado exitosamente.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    user_params_filtered = user_params
    user_params_filtered = user_params_filtered.except(:password, :password_confirmation) if params[:user][:password].blank?

    # Convertir el parámetro admin legacy a role enum
    if params[:user][:admin].present?
      user_params_filtered[:role] = params[:user][:admin].to_s == 'true' ? :admin : :customer
    end

    if @user.update(user_params_filtered)
      redirect_to admin_users_path, notice: 'Usuario actualizado exitosamente.'
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
  end

  def authorize_user
    authorize @user
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :admin, :role)
  end
end