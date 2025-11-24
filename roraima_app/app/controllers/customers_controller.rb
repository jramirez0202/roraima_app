class CustomersController < ApplicationController
  before_action :authorize_customer

  def index
    # Optimization: Use single query to get status counts
    status_counts = current_user.packages.group(:status).count

    @total_packages = current_user.packages.count

    # Counts by specific status
    @pending_pickup_count = status_counts[0] || 0
    @in_warehouse_count = status_counts[1] || 0
    @in_transit_count = status_counts[2] || 0
    @rescheduled_count = status_counts[3] || 0
    @delivered_count = status_counts[4] || 0
    @picked_up_count = status_counts[5] || 0
    @return_count = status_counts[6] || 0
    @cancelled_count = status_counts[7] || 0

    # Grouped counts
    @in_progress_count = @pending_pickup_count + @in_warehouse_count + @in_transit_count + @rescheduled_count + @return_count
    @completed_count = @delivered_count + @picked_up_count + @cancelled_count

    # Upcoming packages (pending pickup with future date)
    @pending_packages = current_user.packages.pendiente_retiro
                                    .where('loading_date >= ?', Date.today)
                                    .count

    # Active exchanges (in progress)
    @exchanges = current_user.packages.en_proceso
                             .where(exchange: true)
                             .count

    # Recent packages in progress
    @recent_packages = current_user.packages.en_proceso
                                   .includes(:region, :commune)
                                   .recent
                                   .limit(5)
  end

  private

  def authorize_customer
    redirect_to admin_packages_path, alert: 'Acceso denegado' if current_user.admin?
  end
end
