class Package < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :region
  belongs_to :commune

  # Enum para estados del paquete
  enum status: {
    active: 0,
    cancelled: 1
  }

  # Validaciones
  validates :region, :commune, :pickup_date, presence: true

  validates :phone,
            format: { with: /\A[\d\s\+\-\(\)]+\z/,
                      message: "solo permite números, espacios y caracteres +-()" },
            allow_blank: true

  validates :pickup_date,
            comparison: { greater_than_or_equal_to: Date.today,
                          message: "debe ser hoy o posterior" },
            allow_nil: false

  # Scopes optimizados para usar índices compuestos
  # Usa index_packages_on_created_at
  scope :recent, -> { order(created_at: :desc) }

  # Usa index_packages_on_user_id_and_status cuando se combina con active/cancelled
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  # Usa index_packages_on_user_id_and_status
  scope :by_user_and_status, ->(user_id, status) { where(user_id: user_id, status: status) }

  # Usa index_packages_on_status
  scope :exchanges, -> { active.where(exchange: true) }

  # Usa index_packages_on_status_and_pickup_date
  scope :for_date, ->(date) { active.where(pickup_date: date) }

  # Usa index_packages_on_status_and_pickup_date de forma óptima
  scope :pending_pickup, -> { where(status: :active).where('pickup_date >= ?', Date.today).order(:pickup_date) }

  # Usa index_packages_on_region_and_commune cuando se combina con by_commune
  scope :by_region, ->(region_id) { where(region_id: region_id) }
  scope :by_region_and_commune, ->(region_id, commune_id) { where(region_id: region_id, commune_id: commune_id) }

  # Método para cancelar paquete
  def cancel!
    update!(
      status: :cancelled,
      cancelled_at: Time.current
    )
  end

  # Helper para verificar si puede ser cancelado
  def cancellable?
    active?
  end
end
