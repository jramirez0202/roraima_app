class CustomersController < ApplicationController
  before_action :authorize_customer

  def index
    # === ESTADÍSTICAS DEL DÍA ACTUAL ===
    # Optimización: Usamos queries con Date.current (timezone Santiago configurado en application.rb)

    today_start = Date.current.beginning_of_day
    today_end = Date.current.end_of_day

    # Contador 1: Paquetes creados/cargados HOY (solo estados visibles)
    # Usa índice: index_packages_on_user_id + index_packages_on_created_at
    today = Date.current
    @today_packages_count = current_user.packages
                                    .customer_visible_statuses  # Filtra por estados visibles
                                    .where(loading_date: today)
                                    .count

    # Contador 2: Paquetes entregados HOY (solo estados visibles)
    # Usa índice: index_packages_on_user_id + delivered_at (si existe)
    # Nota: delivered_at se actualiza cuando status cambia a 'delivered'
    @today_delivered_count = current_user.packages
                                         .customer_visible_statuses  # Filtra por estados visibles
                                         .where(delivered_at: today_start..today_end)
                                         .count

    # === PAQUETES RECIENTES EN PROCESO ===
    # Muestra últimos 5 paquetes activos (no terminados) para dar contexto
    # Usa índice: index_packages_on_user_id_and_status
    @recent_packages = current_user.packages
                                   .customer_visible_statuses  # Filtra por estados visibles
                                   .active  # Scope: excluye delivered, cancelled
                                   .includes(:region, :commune)  # Evita N+1 en la vista
                                   .recent  # Scope: order(created_at: :desc)
                                   .limit(5)
  end

  private

  def authorize_customer
    if current_user.admin?
      redirect_to admin_root_path, alert: 'Acceso denegado'
    elsif current_user.driver?
      redirect_to drivers_root_path, alert: 'Acceso denegado'
    end
  end
end
