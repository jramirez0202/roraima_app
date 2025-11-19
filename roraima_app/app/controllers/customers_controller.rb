class CustomersController < ApplicationController
  before_action :authorize_customer

  def index
    # Optimización: Usar una sola query para obtener conteos por status
    # Aprovecha el índice index_packages_on_user_id_and_status
    status_counts = current_user.packages.group(:status).count

    @total_packages = current_user.packages.count
    @active_packages = status_counts[0] || 0  # active = 0 en el enum
    @cancelled_packages = status_counts[1] || 0  # cancelled = 1 en el enum

    # Query optimizada para pending y exchanges usando los índices compuestos
    @pending_packages = current_user.packages.active
                                    .where('pickup_date >= ?', Date.today)
                                    .count
    @exchanges = current_user.packages.active.where(exchange: true).count

    @recent_packages = current_user.packages.active
                                   .includes(:region, :commune)
                                   .recent
                                   .limit(5)
  end

  private

  def authorize_customer
    redirect_to admin_packages_path, alert: 'Acceso denegado' if current_user.admin?
  end
end
