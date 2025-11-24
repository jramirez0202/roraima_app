class Package < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :region
  belongs_to :commune
  belongs_to :assigned_courier, class_name: 'User', optional: true

  # Enum para estados del paquete (tracking flow)
  enum status: {
    pendiente_retiro: 0,    # Estado inicial - listo para ser retirado
    en_bodega: 1,           # Almacenado en centro/depósito
    en_camino: 2,           # En tránsito hacia entrega
    reprogramado: 3,        # Intento fallido, nueva fecha asignada
    entregado: 4,           # Entrega completada (terminal)
    retirado: 5,            # Cliente retiró en punto (terminal)
    devolucion: 6,          # Proceso devolución al remitente
    cancelado: 7            # Envío anulado (terminal)
  }

  # Matriz de transiciones permitidas
  ALLOWED_TRANSITIONS = {
    pendiente_retiro: [:en_bodega, :cancelado, :retirado],
    en_bodega: [:en_camino, :retirado, :devolucion, :cancelado],
    en_camino: [:entregado, :reprogramado, :devolucion],
    reprogramado: [:en_camino, :devolucion],
    entregado: [],  # Terminal
    retirado: [],   # Terminal
    devolucion: [:en_bodega, :cancelado],
    cancelado: []   # Terminal
  }.freeze

  # Estados terminales (no permiten más transiciones)
  TERMINAL_STATUSES = [:entregado, :retirado, :cancelado].freeze

  # Validaciones
  validates :region, :commune, :loading_date, presence: true

  validates :phone,
            presence: { message: "es obligatorio" },
            format: { with: /\A\+569\d{8}\z/,
                      message: "debe tener formato +569XXXXXXXX (12 caracteres)" },
            on: [:create, :update]

  validates :loading_date, presence: true
  validate :loading_date_cannot_be_in_past

  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  validates :address,
            length: { maximum: 100, message: "no puede tener más de 100 caracteres" },
            allow_blank: true

  validates :description,
            length: { maximum: 100, message: "no puede tener más de 100 caracteres" },
            allow_blank: true

  # Validaciones para etiquetas
  validates :tracking_code, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_tracking_code, on: :create

  # Scopes optimizados para usar índices compuestos
  # Usa index_packages_on_created_at
  scope :recent, -> { order(created_at: :desc) }

  # Usa index_packages_on_user_id_and_status
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_user_and_status, ->(user_id, status) { where(user_id: user_id, status: status) }

  # Usa index_packages_on_status
  scope :terminals, -> { where(status: TERMINAL_STATUSES) }
  scope :en_proceso, -> { where.not(status: TERMINAL_STATUSES) }
  scope :exchanges, -> { where(exchange: true) }

  # Usa index_packages_on_status_and_loading_date
  scope :for_date, ->(date) { where(loading_date: date) }
  scope :pending_pickup, -> { where(status: :pendiente_retiro).where('loading_date >= ?', Date.today).order(:loading_date) }

  # Usa index_packages_on_region_and_commune
  scope :by_region, ->(region_id) { where(region_id: region_id) }
  scope :by_region_and_commune, ->(region_id, commune_id) { where(region_id: region_id, commune_id: commune_id) }

  # Usa index_packages_on_status_and_assigned_courier_id
  scope :by_courier, ->(courier_id) { where(assigned_courier_id: courier_id) }
  scope :unassigned, -> { where(assigned_courier_id: nil) }

  # Scopes por estado específico
  scope :en_transito, -> { where(status: [:en_bodega, :en_camino, :reprogramado]) }
  scope :necesitan_atencion, -> { where(status: [:reprogramado, :devolucion]) }

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
      raise StandardError, "Transición no permitida: #{status} → #{new_status_sym}"
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

  # Actualiza timestamps correspondientes según el nuevo estado
  def update_timestamps_for_status(new_status)
    case new_status.to_sym
    when :en_bodega
      self.picked_at = Time.current if picked_at.nil?
    when :en_camino
      self.shipped_at = Time.current if shipped_at.nil?
    when :entregado, :retirado
      self.delivered_at = Time.current
    when :cancelado
      self.cancelled_at = Time.current
    end
  end

  # Método para cancelar paquete (wrapper de transition_to!)
  def cancel!(user:, reason: nil)
    transition_to!(:cancelado, user: user, reason: reason)
  end

  # Helper para verificar si puede ser cancelado
  def cancellable?
    can_transition_to?(:cancelado)
  end

  # Incrementa el contador de intentos de entrega
  def increment_attempts!
    increment!(:attempts_count)
  end

  # Nombre legible del estado
  def readable_status
    I18n.t("activerecord.attributes.package.statuses.#{status}", default: status.humanize)
  end

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
      company: company.presence || "N/A"
    }.to_json
  end

  private

  # Validación personalizada para fecha de carga
  def loading_date_cannot_be_in_past
    return if loading_date.blank?

    if loading_date < Date.today
      errors.add(:loading_date, "debe ser hoy o posterior")
    end
  end
end
