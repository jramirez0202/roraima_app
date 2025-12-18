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
    return stored if stored

    if resource.driver?
      drivers_root_path
    elsif resource.admin?
      admin_root_path
    else
      customers_dashboard_path
    end
  end
end
