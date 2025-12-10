class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pundit::Authorization

  before_action :authenticate_user!, unless: :devise_controller?

  # Handle authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "No tienes permiso para realizar esta acción."
    redirect_to(request.referrer || root_path)
  end

  # Redirigir después del login según el rol
  def after_sign_in_path_for(resource)
    return stored_location_for(resource) if stored_location_for(resource)

    case
    when resource.admin?
      admin_root_path
    when resource.is_a?(Driver)
      drivers_root_path
    else
      customers_dashboard_path
    end
  end
end