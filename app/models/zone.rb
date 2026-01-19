class Zone < ApplicationRecord
  belongs_to :region
  has_many :drivers, foreign_key: :assigned_zone_id, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  def commune_names
    Commune.where(id: communes).pluck(:name)
  end
end
