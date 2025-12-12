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
            presence: true,
            uniqueness: true,
            format: {
              with: /\A[A-Z]{2}\d{4}|[A-Z]{4}\d{2}\z/,
              message: "debe ser formato chileno (ABCD12 o AB1234)"
            }

  validates :vehicle_model, presence: true
  validates :vehicle_capacity,
            numericality: { greater_than: 0 },
            allow_nil: false

  # Scope: All assigned packages (from pending_pickup onwards)
  def visible_packages
    assigned_packages
  end

  # Daily statistics
  def today_deliveries
    visible_packages.where(delivered_at: Date.current.all_day)
  end

  def pending_deliveries
    visible_packages.where(status: [:in_transit, :rescheduled])
  end

  # Status counters for assigned packages by date
  def pending_count(date = Date.current)
    visible_packages
      .where(assigned_at: date.all_day)
      .where(status: [:in_warehouse, :in_transit])
      .count
  end

  def delivered_count(date = Date.current)
    visible_packages
      .where(assigned_at: date.all_day)
      .where(status: [:delivered, :picked_up])
      .count
  end

  def rescheduled_count(date = Date.current)
    visible_packages
      .where(assigned_at: date.all_day)
      .where(status: :rescheduled)
      .count
  end

  def cancelled_count(date = Date.current)
    visible_packages
      .where(assigned_at: date.all_day)
      .where(status: :cancelled)
      .count
  end

  # Status summary for specific date
  def status_summary(date = Date.current)
    {
      pending: pending_count(date),
      delivered: delivered_count(date),
      rescheduled: rescheduled_count(date),
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

  # Business logic: Can driver start route?
  def can_start_route?
    # Only validate authorization if system requires it
    authorization_check = if Setting.require_driver_authorization?
                           ready_for_route?
                         else
                           true
                         end

    authorization_check &&
    pending_deliveries.count > 0 &&
    (not_started? || ready?)
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
