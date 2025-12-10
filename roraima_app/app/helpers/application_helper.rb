module ApplicationHelper
  include Pagy::Frontend
  include PackagesHelper

  def dashboard_path_for(user)
    return root_path unless user

    if user.admin?
      admin_root_path
    elsif user.is_a?(Driver)
      drivers_root_path
    else
      customers_dashboard_path
    end
  end

  # Alias para compatibilidad con diferentes vistas
  def status_badge_class(status)
    status_badge_classes(status)
  end
end