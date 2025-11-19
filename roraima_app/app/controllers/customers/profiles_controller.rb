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

      if @user.update(user_params)
        redirect_to customers_profile_path, notice: 'Perfil actualizado exitosamente.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation)
    end
  end
end
