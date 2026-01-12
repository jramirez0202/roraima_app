class Driver < User
  # STI: Hereda de User automáticamente

  belongs_to :assigned_zone, class_name: 'Zone', optional: true
  has_many :assigned_packages,
           foreign_key: :assigned_courier_id,
           class_name: 'Package',
           dependent: :nullify

  # Route history tracking
  has_many :routes,
           foreign_key: :driver_id,
           class_name: 'Route',
           dependent: :destroy

  # Validaciones específicas de Driver
  validates :name, presence: true

  validates :vehicle_plate,
            uniqueness: true,
            format: {
              with: /\A[A-Z]{2}\d{4}|[A-Z]{4}\d{2}\z/,
              message: "debe ser formato chileno (ABCD12 o AB1234)"
            },
            allow_blank: true

  validates :vehicle_model, presence: false
  validates :vehicle_capacity,
            numericality: { greater_than: 0 },
            allow_nil: true

  # Scope: All assigned packages (from pending_pickup onwards)
  def visible_packages
    assigned_packages
  end

  # Daily statistics
  def today_deliveries
    visible_packages.where(delivered_at: Date.current.all_day)
  end

  # Paquetes pendientes de entrega (todos los que están en proceso)
  def pending_deliveries
    visible_packages.where(status: [:pending_pickup, :in_warehouse, :in_transit, :rescheduled])
  end

  # === WEEKLY STATISTICS ===
  # Semana laboral chilena: Lunes a Domingo

  # Obtiene el lunes de la semana para una fecha dada
  def week_start_for(date)
    date.beginning_of_week(:monday)
  end

  # Obtiene el domingo de la semana para una fecha dada
  def week_end_for(date)
    date.end_of_week(:monday)
  end

  # Estadísticas semanales completas
  def weekly_summary(week_start_date)
    week_start = week_start_date.is_a?(Date) ? week_start_date : Date.parse(week_start_date)
    week_end = week_end_for(week_start)

    {
      delivered: weekly_delivered_count(week_start, week_end),
      rescheduled: weekly_rescheduled_count(week_start, week_end),
      cancelled: weekly_cancelled_count(week_start, week_end),
      week_start: week_start,
      week_end: week_end
    }
  end

  # Paquetes entregados en la semana (usa delivered_at) - ESTOS SE PAGAN
  def weekly_delivered_count(week_start, week_end)
    visible_packages
      .where(status: :delivered)
      .where(delivered_at: week_start.beginning_of_day..week_end.end_of_day)
      .count
  end

  # Paquetes reprogramados en la semana - SOLO INFORMACIÓN, NO SE PAGAN
  # Solo cuenta los que AÚN están en estado rescheduled
  def weekly_rescheduled_count(week_start, week_end)
    visible_packages
      .where(status: :rescheduled)
      .where(updated_at: week_start.beginning_of_day..week_end.end_of_day)
      .count
  end

  # Paquetes cancelados en la semana (usa cancelled_at) - SOLO INFORMACIÓN
  def weekly_cancelled_count(week_start, week_end)
    visible_packages
      .where(status: :cancelled)
      .where(cancelled_at: week_start.beginning_of_day..week_end.end_of_day)
      .count
  end

  # Reprogramados persistentes (históricos) - NO filtra por fecha de asignación
  # NOTA: Los paquetes rescheduled SÍ mantienen assigned_courier_id
  # porque el driver sigue siendo responsable de ellos
  def persistent_rescheduled
    visible_packages.where(status: :rescheduled)
  end

  def persistent_rescheduled_count
    persistent_rescheduled.count
  end

  # Status counters for assigned packages by date
  def pending_count(date = Date.current)
    # Si está en ruta, cuenta TODOS los paquetes pendientes actuales
    # (sin importar cuándo fueron asignados - pueden ser asignados durante la ruta)
    if on_route?
      # Paquetes actualmente pendientes
      in_process = visible_packages
                    .where(status: [:in_warehouse, :in_transit])
                    .count

      historic_rescheduled = persistent_rescheduled_count
      in_process + historic_rescheduled
    else
      # Lógica normal: paquetes del día + reprogramados históricos
      new_today = visible_packages
                    .where(assigned_at: date.all_day)
                    .where(status: [:in_warehouse, :in_transit])
                    .count

      historic_rescheduled = persistent_rescheduled_count
      new_today + historic_rescheduled
    end
  end

  def delivered_count(date = Date.current)
    # IMPORTANTE: Ahora los paquetes delivered se desasignan automáticamente
    # Debemos buscar en status_history con JSONB query
    if on_route? && route_started_at.present?
      # Paquetes entregados DESPUÉS de iniciar la ruta
      Package
        .where(status: :delivered)
        .where('delivered_at >= ?', route_started_at)
        .where("status_history @> ?", [{ assigned_courier_id: id, status: 'delivered' }].to_json)
        .count
    else
      # Paquetes entregados en la fecha especificada que fueron asignados a este driver
      Package
        .where(status: :delivered)
        .where(delivered_at: date.all_day)
        .where("status_history @> ?", [{ assigned_courier_id: id, status: 'delivered' }].to_json)
        .count
    end
  end

  def rescheduled_count(date = Date.current)
    # DEPRECATED: Usa persistent_rescheduled_count en su lugar
    # Mantenido por compatibilidad
    # NOTA: Los paquetes rescheduled SÍ mantienen assigned_courier_id
    # porque el driver sigue siendo responsable de ellos
    visible_packages
      .where(assigned_at: date.all_day)
      .where(status: :rescheduled)
      .count
  end

  def cancelled_count(date = Date.current)
    # IMPORTANTE: Ahora los paquetes cancelled se desasignan automáticamente
    # Debemos buscar en status_history con JSONB query
    if on_route? && route_started_at.present?
      # Paquetes cancelados DESPUÉS de iniciar la ruta
      Package
        .where(status: :cancelled)
        .where('cancelled_at >= ?', route_started_at)
        .where("status_history @> ?", [{ assigned_courier_id: id, status: 'cancelled' }].to_json)
        .count
    else
      # Paquetes cancelados en la fecha especificada que fueron asignados a este driver
      Package
        .where(status: :cancelled)
        .where(cancelled_at: date.all_day)
        .where("status_history @> ?", [{ assigned_courier_id: id, status: 'cancelled' }].to_json)
        .count
    end
  end

  # Status summary for specific date
  def status_summary(date = Date.current)
    {
      pending: pending_count(date),
      delivered: delivered_count(date),
      rescheduled: persistent_rescheduled_count, # Usa contador persistente
      cancelled: cancelled_count(date)
    }
  end

  # Route status enum
  enum route_status: {
    not_started: 0,
    ready: 1,
    on_route: 2,
    completed: 3
  }

  # Route management scopes
  scope :ready_for_routes, -> { where(ready_for_route: true) }
  scope :currently_on_route, -> { where(route_status: :on_route) }

  # Check if driver is currently on route
  # This method should be auto-generated by enum but we define it explicitly
  # to ensure it exists (fixes NoMethodError bug)
  def on_route?
    route_status == 'on_route' || current_route.present?
  end

  # Business logic: Can driver start route?
  def can_start_route?
    # Only validate authorization if system requires it
    authorization_check = if Setting.require_driver_authorization?
                           ready_for_route?
                         else
                           true
                         end

    # Puede iniciar si:
    # 1. Está autorizado (si se requiere)
    # 2. Tiene paquetes pendientes (pending_pickup, in_warehouse, in_transit, rescheduled)
    # 3. NO está actualmente en ruta (puede estar en not_started, ready, o completed)
    authorization_check &&
    pending_deliveries.count > 0 &&
    !on_route?
  end

  # Progress tracking for navbar counter
  def route_progress
    return { delivered: 0, total: 0 } unless on_route?

    total = assigned_packages.count
    delivered = assigned_packages.where(status: :delivered).count

    { delivered: delivered, total: total }
  end

  # Percentage calculation
  def route_completion_percentage
    progress = route_progress
    return 0 if progress[:total].zero?

    ((progress[:delivered].to_f / progress[:total]) * 100).round(1)
  end

  # Business logic: Get last N routes ordered chronologically
  def last_routes(limit: 3)
    routes.order(started_at: :desc).limit(limit)
  end

  # Get current active route (if any)
  def current_route
    routes.where(status: :active).first
  end

  # Statistics: Total routes completed
  def total_routes_completed
    routes.where(status: :completed).count
  end
end
