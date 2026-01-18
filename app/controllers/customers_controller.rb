class CustomersController < ApplicationController
  before_action :authorize_customer

  def index
    # === FILTRO DE FECHA PARA RESUMEN ===
    # Permite filtrar por rango de fechas de carga (loading_date)
    @date_from = parse_date(params[:date_from]) || Date.current
    @date_to = parse_date(params[:date_to]) || Date.current

    # Base query: paquetes del cliente con estados visibles
    base_packages = current_user.packages.customer_visible_statuses

    # Paquetes filtrados por fecha de carga
    packages_in_date_range = base_packages.where(loading_date: @date_from..@date_to)

    # === CONTADORES POR ESTADO (RESUMEN DEL DÍA) ===
    status_counts = packages_in_date_range.group(:status).count
    @total_count = packages_in_date_range.count
    @pending_pickup_count = status_counts["pending_pickup"] || 0
    @in_warehouse_count = status_counts["in_warehouse"] || 0
    @in_transit_count = status_counts["in_transit"] || 0
    @rescheduled_count = status_counts["rescheduled"] || 0
    @delivered_count = status_counts["delivered"] || 0
    @return_count = status_counts["return"] || 0
    @cancelled_count = status_counts["cancelled"] || 0

    # Contador de reprogramados persistentes (sin filtro de fecha - para alerta global)
    @persistent_rescheduled_count = base_packages.where(status: :rescheduled).count

    # === ESTADÍSTICAS ADICIONALES ===
    today_start = Date.current.beginning_of_day
    today_end = Date.current.end_of_day

    # Paquetes cargados hoy (independiente del filtro)
    @today_packages_count = base_packages.where(loading_date: Date.current).count

    # Paquetes entregados hoy (independiente del filtro)
    @today_delivered_count = base_packages.where(delivered_at: today_start..today_end).count

    # === PAQUETES RECIENTES EN PROCESO ===
    # Muestra últimos 5 paquetes activos (no terminados) para dar contexto
    @recent_packages = base_packages
                         .active
                         .includes(:region, :commune)
                         .recent
                         .limit(5)

    # Preservar parámetros de filtro para los links
    @filter_params = { date_from: @date_from, date_to: @date_to }.compact
  end

  private

  def authorize_customer
    if current_user.admin?
      redirect_to admin_root_path, alert: 'Acceso denegado'
    elsif current_user.driver?
      redirect_to drivers_root_path, alert: 'Acceso denegado'
    end
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError, TypeError
    nil
  end
end
