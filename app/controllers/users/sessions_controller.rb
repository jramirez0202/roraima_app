# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # Override create to handle Turbo Stream redirects properly
  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?

    redirect_url = get_redirect_url_for(resource)

    respond_to do |format|
      format.html { redirect_to redirect_url, allow_other_host: false }
      format.turbo_stream { redirect_to redirect_url, status: :see_other, allow_other_host: false }
    end
  end

  protected

  def get_redirect_url_for(resource)
    stored = stored_location_for(resource)

    # Validar que la ubicación almacenada sea apropiada para el rol del usuario
    if stored && valid_path_for_role?(stored, resource)
      return stored
    end

    # Redirigir según el rol
    if resource.driver?
      drivers_root_path
    elsif resource.admin?
      admin_root_path
    else
      customers_dashboard_path
    end
  end

  def valid_path_for_role?(path, resource)
    return true if resource.admin? # Los admins pueden acceder a cualquier ruta

    if resource.driver?
      path.start_with?('/drivers')
    elsif resource.customer?
      path.start_with?('/customers')
    else
      false
    end
  end
end
