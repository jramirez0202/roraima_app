class Region < ApplicationRecord
  has_many :communes, dependent: :destroy
  has_many :packages, dependent: :nullify
  
  validates :name, presence: true, uniqueness: true
  
  scope :ordered, -> { order(:name) }
end

