class Package < ApplicationRecord
  belongs_to :user
  belongs_to :region
  belongs_to :commune
  belongs_to :assigned_courier, class_name: 'User', optional: true
  belongs_to :assigned_by, class_name: 'User', optional: true
  belongs_to :bulk_upload, optional: true

  # Active Storage attachments
  has_many_attached :reschedule_photos
  has_many_attached :proof_photos

  # Enum for package status (tracking flow)
  enum status: {
    pending_pickup: 0,      # Initial state - ready to be picked up
    in_warehouse: 1,        # Stored in warehouse/depot
    in_transit: 2,          # In transit to delivery
    rescheduled: 3,         # Failed attempt, new date assigned
    delivered: 4,           # Delivery completed (terminal)
    return: 6,              # Return process to sender
    cancelled: 7            # Shipment cancelled (terminal)
  }

  # Allowed transitions matrix
  ALLOWED_TRANSITIONS = {
    pending_pickup: [:in_warehouse, :cancelled],
    in_warehouse: [:in_transit, :return],
    in_transit: [:delivered, :rescheduled, :return, :cancelled],
    rescheduled: [:in_transit, :return, :cancelled],
    delivered: [],  # Terminal
    return: [:in_warehouse, :cancelled],
    cancelled: []   # Terminal
  }.freeze

  # Terminal statuses (no more transitions allowed)
  TERMINAL_STATUSES = [:delivered, :cancelled].freeze

  # Validaciones
  validates :region, :commune, :loading_date, presence: true

  validates :phone,
            presence: { message: "es obligatorio" },
            format: { with: /\A\+569\d{8}\z/,
                      message: "debe tener formato +569XXXXXXXX (12 caracteres)" },
            on: [:create, :update]

  validates :loading_date, presence: true
  validate :loading_date_must_be_before_delivery
  validate :user_must_be_customer

  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  validates :address,
            length: { maximum: 100, message: "no puede tener más de 100 caracteres" },
            allow_blank: true

  validates :description,
            length: { maximum: 100, message: "no puede tener más de 100 caracteres" },
            allow_blank: true

  validates :reprogram_motive,
            length: { maximum: 30, message: "no puede tener más de 30 caracteres" },
            allow_blank: true

  # Validaciones para etiquetas
  validates :tracking_code, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_tracking_code, on: :create
  before_validation :set_loading_date_default, on: :create

  # Scopes optimizados para usar índices compuestos
  # Usa index_packages_on_created_at
  scope :recent, -> { order(created_at: :desc) }

  # Usa index_packages_on_user_id_and_status
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_user_and_status, ->(user_id, status) { where(user_id: user_id, status: status) }

  # Uses index_packages_on_status
  scope :terminals, -> { where(status: TERMINAL_STATUSES) }
  scope :active, -> { where.not(status: TERMINAL_STATUSES) }
  scope :exchanges, -> { where(exchange: true) }

  # Uses index_packages_on_status_and_loading_date
  scope :for_date, ->(date) { where(loading_date: date) }
  scope :pending_for_pickup, -> { where(status: :pending_pickup).where('loading_date >= ?', Date.current).order(:loading_date) }

  # Usa index_packages_on_region_and_commune
  scope :by_region, ->(region_id) { where(region_id: region_id) }
  scope :by_region_and_commune, ->(region_id, commune_id) { where(region_id: region_id, commune_id: commune_id) }

  # Usa index_packages_on_status_and_assigned_courier_id
  scope :by_courier, ->(courier_id) { where(assigned_courier_id: courier_id) }
  scope :unassigned, -> { where(assigned_courier_id: nil) }

  # Ordenar por fecha de asignación (más reciente primero) - Para vista de drivers
  # Usa index_packages_on_assigned_courier_id_and_assigned_at
  scope :recent_assignments_first, -> { order(assigned_at: :desc, created_at: :desc) }

  # Scopes by specific status
  scope :in_progress, -> { where(status: [:in_warehouse, :in_transit, :rescheduled]) }
  scope :needs_attention, -> { where(status: [:rescheduled, :return]) }

  # Filtra paquetes con estados visibles para clientes
  # Solo muestra paquetes cuyos estados estén configurados como visibles en Setting
  scope :customer_visible_statuses, -> {
    visible_statuses = Setting.customer_visible_statuses
    where(status: visible_statuses)
  }

  # === FILTRADO AVANZADO ===

  # Búsqueda parcial por tracking code (case-insensitive)
  scope :search_by_tracking, ->(query) {
    where("tracking_code ILIKE ?", "%#{sanitize_sql_like(query)}%") if query.present?
  }

  # Filtrar por múltiples comunas (IN query)
  scope :by_communes, ->(commune_ids) {
    where(commune_id: commune_ids) if commune_ids.present?
  }

  # Filtrar por múltiples drivers (IN query)
  scope :by_couriers, ->(courier_ids) {
    where(assigned_courier_id: courier_ids) if courier_ids.present?
  }

  # Rango de fechas de carga (desde/hasta)
  scope :loading_date_between, ->(start_date, end_date) {
    result = all
    result = result.where('loading_date >= ?', start_date) if start_date.present?
    result = result.where('loading_date <= ?', end_date) if end_date.present?
    result
  }

  # Rango de fechas de creación (desde/hasta)
  scope :created_between, ->(start_date, end_date) {
    result = all
    result = result.where('created_at >= ?', start_date.beginning_of_day) if start_date.present?
    result = result.where('created_at <= ?', end_date.end_of_day) if end_date.present?
    result
  }

  # ======================
  # Métodos de tracking
  # ======================

  # Verifica si el paquete está en un estado terminal
  def terminal?
    TERMINAL_STATUSES.include?(status.to_sym)
  end

  # Verifica si el paquete está activo (no terminal)
  def active?
    !terminal?
  end

  # Verifica si una transición es permitida
  def can_transition_to?(new_status, override: false)
    return true if override # Admin puede forzar cualquier transición

    new_status_sym = new_status.to_sym
    current_status_sym = status.to_sym

    # No permitir transiciones desde estados terminales sin override
    return false if terminal? && !override

    # Verificar si la transición está en la matriz
    ALLOWED_TRANSITIONS[current_status_sym]&.include?(new_status_sym) || false
  end

  # Ejecuta una transición de estado con validación y registro
  def transition_to!(new_status, user:, reason: nil, location: nil, override: false)
    new_status_sym = new_status.to_sym

    # Validar transición
    unless can_transition_to?(new_status_sym, override: override)
      current_text = translate_status(status)
      new_status_text = translate_status(new_status_sym)
      raise StandardError, "Transición no permitida: #{current_text} → #{new_status_text}"
    end

    # Guardar estado anterior
    self.previous_status = Package.statuses[status]

    # Registrar en historial
    add_to_history(
      status: new_status_sym,
      user_id: user.id,
      reason: reason,
      location: location,
      override: override
    )

    # Actualizar timestamps según el nuevo estado
    update_timestamps_for_status(new_status_sym)

    # Actualizar estado
    self.status = new_status_sym
    self.admin_override = override
    self.location = location if location.present?

    # Guardar
    save!
  end

  # Agrega un registro al historial de estados
  def add_to_history(status:, user_id:, reason: nil, location: nil, override: false)
    history_entry = {
      status: status.to_s,
      previous_status: self.status,
      timestamp: Time.current.iso8601,
      user_id: user_id,
      reason: reason,
      location: location,
      override: override
    }

    self.status_history ||= []
    self.status_history << history_entry
  end

  # Updates timestamps according to the new status
  def update_timestamps_for_status(new_status)
    case new_status.to_sym
    when :in_warehouse
      self.picked_at = Time.current if picked_at.nil?
    when :in_transit
      self.shipped_at = Time.current if shipped_at.nil?
    when :delivered
      self.delivered_at = Time.current
    when :cancelled
      self.cancelled_at = Time.current
    end
  end

  # Method to cancel package (wrapper for transition_to!)
  def cancel!(user:, reason: nil)
    transition_to!(:cancelled, user: user, reason: reason)
  end

  # Helper to check if it can be cancelled
  def cancellable?
    can_transition_to?(:cancelled)
  end

  # Incrementa el contador de intentos de entrega
  def increment_attempts!
    increment!(:attempts_count)
  end

  # Nombre legible del estado en español
  # Delega al helper centralizado para evitar duplicación
  def readable_status
    ApplicationController.helpers.status_text(status)
  end
  alias_method :status_i18n, :readable_status

  # Helper para formatear monto en pesos chilenos
  def formatted_amount
    # Convertir a entero si no tiene decimales
    value = amount % 1 == 0 ? amount.to_i : amount
    "$#{ActionController::Base.helpers.number_with_delimiter(value, delimiter: '.')} CLP"
  end

  # Método para generar código de tracking único
  def generate_tracking_code
    return if tracking_code.present?

    self.tracking_code = loop do
      random_digits = 14.times.map { rand(0..9) }.join
      code = "PKG-#{random_digits}"
      break code unless Package.exists?(tracking_code: code)
    end
  end

  # Validar si el paquete está listo para generar etiqueta
  def ready_for_label?
    tracking_code.present? &&
      customer_name.present? &&
      address.present? &&
      phone.present? &&
      commune.present? &&
      loading_date.present?
  end

  # Datos para el código QR en formato JSON
  def qr_data
    {
      tracking: tracking_code,
      delivery: loading_date&.strftime('%Y-%m-%d'),
      customer: customer_name,
      phone: phone,
      address: address,
      commune: commune&.name,
      notes: description.presence || "Sin indicaciones",
      company: company_name.presence || "N/A"
    }.to_json
  end

  private

  # Establece loading_date automáticamente si está vacío
  def set_loading_date_default
    self.loading_date ||= Date.current
  end

  # Validación de coherencia temporal: loading_date debe ser anterior a delivered_at
  def loading_date_must_be_before_delivery
    return if loading_date.blank? || delivered_at.blank?

    if loading_date > delivered_at.to_date
      errors.add(:loading_date, "no puede ser posterior a la fecha de entrega (#{delivered_at.to_date.strftime('%d/%m/%Y')})")
    end
  end

  def user_must_be_customer
    return if user.nil?

    # Verificar que el usuario no sea un Driver ni un Admin
    if user.driver?
      errors.add(:user_id, "no puede ser un Driver. Debe ser un usuario Customer.")
    elsif user.admin?
      errors.add(:user_id, "no puede ser un Admin. Debe ser un usuario Customer.")
    end
  end

  # Traduce el estado del paquete a español
  # Delega al helper centralizado para evitar duplicación
  def translate_status(status)
    ApplicationController.helpers.status_text(status)
  end
end
