class Commune < ApplicationRecord
  belongs_to :region
  has_many :packages, dependent: :nullify
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: :region_id }
  
  scope :ordered, -> { order(:name) }
  scope :by_region, ->(region_id) { where(region_id: region_id).ordered }
  
  def full_name
    "#{name}, #{region.name}"
  end
end