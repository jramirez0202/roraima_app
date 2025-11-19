class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles enum - preparado para futuros roles
  enum role: {
    admin: 0,
    customer: 1
    # Futuros roles: manager: 2, driver: 3, etc.
  }

  has_many :packages, dependent: :destroy
  validates :email, presence: true, uniqueness: true

  # Nota: enum automáticamente crea métodos admin? y customer?
  # Pero también mantenemos compatibilidad con el campo boolean admin
  def admin?
    # Primero verifica el enum, luego el campo boolean legacy
    super rescue (read_attribute(:admin) == true)
  end
end