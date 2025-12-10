class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles enum
  enum role: {
    admin: 0,
    customer: 1,
    driver: 2
  }

  has_many :packages, dependent: :destroy
  has_many :bulk_uploads, dependent: :destroy

  # Asociación inversa para auditoría: paquetes asignados por este usuario (admin)
  has_many :assigned_packages,
           class_name: 'Package',
           foreign_key: 'assigned_by_id',
           dependent: :nullify

  has_one_attached :company_logo

  # Validaciones obligatorias básicas
  validates :email, presence: true, uniqueness: true
  validates :rut,
            presence: { message: "no puede estar vacío" },
            uniqueness: true,
            format: { with: /\A\d{1,2}\.\d{3}\.\d{3}-[\dkK]\z/,
                      message: "debe tener formato válido (ej: 12.345.678-9)" },
            unless: :admin?

  # Phone obligatorio para customers y drivers
  validates :phone,
            presence: { message: "no puede estar vacío" },
            format: { with: /\A\+569\d{8}\z/,
                      message: "debe tener formato +569XXXXXXXX (12 caracteres)" },
            if: -> { customer? || driver? }

  # Phone opcional para admins (solo validar formato si se proporciona)
  validates :phone,
            format: { with: /\A\+569\d{8}\z/,
                      message: "debe tener formato +569XXXXXXXX (12 caracteres)",
                      allow_blank: true },
            if: :admin?

  # Company obligatorio para customers
  validates :company,
            presence: { message: "no puede estar vacío" },
            if: :customer?

  # Delivery charge obligatorio y numérico para customers
  validates :delivery_charge,
            presence: { message: "no puede estar vacío" },
            numericality: { greater_than_or_equal_to: 0 },
            if: :customer?

  validates :company_logo, content_type: { in: ['image/png', 'image/gif'],
                                            message: 'debe ser una imagen PNG o GIF con fondo transparente' },
                           size: { less_than: 5.megabytes,
                                   message: 'debe ser menor a 5MB' }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_role, ->(role) { where(role: role) }
  scope :customers_active, -> { where(role: :customer, active: true) }
  scope :drivers_active, -> { where(role: :driver, active: true) }

  # Métodos de instancia

  # Retorna el nombre completo del usuario
  def full_name
    company.present? ? company : rut
  end

  # Retorna el nombre del rol en español
  def display_role
    I18n.t("activerecord.attributes.user.roles.#{role}", default: role.humanize)
  end

  # Retorna el cargo por envío formateado en pesos chilenos
  def formatted_delivery_charge
    return "$0 CLP" if delivery_charge.nil? || delivery_charge.zero?
    value = delivery_charge % 1 == 0 ? delivery_charge.to_i : delivery_charge
    "$#{ActionController::Base.helpers.number_with_delimiter(value, delimiter: '.')} CLP"
  end

  # Verifica si el usuario tiene logo y está habilitado para mostrarse en etiquetas
  def logo_enabled_for_labels?
    company_logo.attached? && show_logo_on_labels?
  end

  # Nota: enum automáticamente crea métodos admin? y customer?
  # Pero también mantenemos compatibilidad con el campo boolean admin
  def admin?
    # Primero verifica el enum, luego el campo boolean legacy
    super rescue (read_attribute(:admin) == true)
  end

  def active_for_authentication?
    super && active?
  end

def inactive_message
  active? ? super : :inactive_account
end

end