class Route < ApplicationRecord
  # Associations
  belongs_to :driver, class_name: 'Driver', foreign_key: :driver_id

  # Enum for route status
  enum status: {
    active: 0,      # Route in progress
    completed: 1    # Route finished
  }

  # Validations
  validates :driver, presence: true
  validates :started_at, presence: true
  validates :packages_delivered, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true

  # Custom validation: ended_at must be after started_at
  validate :ended_at_after_started_at, if: -> { ended_at.present? }

  # Scopes
  scope :by_driver, ->(driver_id) { where(driver_id: driver_id) }
  scope :recent_first, -> { order(started_at: :desc) }
  scope :completed_routes, -> { where(status: :completed) }
  scope :active_routes, -> { where(status: :active) }

  # Business logic: Auto-rotate to keep only last 3 routes per driver
  def self.rotate_for_driver(driver_id)
    routes = by_driver(driver_id).recent_first.to_a

    # If more than 3 routes exist, delete the oldest ones
    if routes.size > 3
      routes_to_delete = routes[3..]
      where(id: routes_to_delete.map(&:id)).destroy_all

      Rails.logger.info "[Route] Rotated routes for driver #{driver_id}: kept #{routes[0..2].map(&:id)}, deleted #{routes_to_delete.size} old routes"
    end
  end

  # Calculate route duration in hours (rounded)
  def duration_in_hours
    return nil unless started_at && ended_at

    ((ended_at - started_at) / 3600.0).round(1)
  end

  # Human-readable status (Spanish)
  def status_i18n
    case status.to_sym
    when :active
      "En Curso"
    when :completed
      "Completada"
    else
      status.to_s.humanize
    end
  end

  private

  def ended_at_after_started_at
    if ended_at <= started_at
      errors.add(:ended_at, "debe ser posterior a la fecha de inicio")
    end
  end
end
