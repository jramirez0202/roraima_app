module Customers
  class ProfilesController < ApplicationController
    def show
      @user = current_user
      authorize @user
    end

    def edit
      @user = current_user
      authorize @user
    end

    def update
      @user = current_user
      authorize @user

      # Eliminar logo si se solicita
      if params[:remove_logo] == '1'
        @user.company_logo.purge
      end

      # Preparar parámetros - remover password si está vacío
      update_params = user_params
      if update_params[:password].blank?
        update_params.delete(:password)
        update_params.delete(:password_confirmation)
      end

      if @user.update(update_params)
        # Bypass de confirmación de Devise si solo se actualiza el email
        bypass_sign_in(@user, scope: :user) if update_params[:email].present?
        redirect_to customers_profile_path, notice: 'Perfil actualizado exitosamente.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation, :company_logo, :show_logo_on_labels)
    end
  end
end
