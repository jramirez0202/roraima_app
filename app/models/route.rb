class Route < ApplicationRecord
  # Associations
  belongs_to :driver, class_name: 'Driver', foreign_key: :driver_id
  belongs_to :closed_by, class_name: 'User', foreign_key: :closed_by_id, optional: true

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
  scope :old_active_routes, -> { active_routes.where.not('DATE(started_at) = ?', Date.current) }
  scope :forced_closed, -> { where.not(forced_closed_at: nil) }

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

  # Truncate notes for display (max 50 chars)
  def notes_truncated(limit = 50)
    return nil unless notes.present?
    notes.length > limit ? "#{notes[0...limit]}..." : notes
  end

  # Check if route was force-closed by admin
  def forced_closed?
    forced_closed_at.present?
  end

  # Human-readable forced close info
  def forced_close_info
    return nil unless forced_closed?
    "Cerrada forzadamente por #{closed_by&.email || 'Admin'} el #{forced_closed_at.strftime('%d/%m/%Y %H:%M')}"
  end

  private

  def ended_at_after_started_at
    if ended_at <= started_at
      errors.add(:ended_at, "debe ser posterior a la fecha de inicio")
    end
  end
end
