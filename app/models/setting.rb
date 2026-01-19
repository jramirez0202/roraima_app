# frozen_string_literal: true

class Setting < ApplicationRecord
  # Singleton pattern - only one settings record should exist
  validates :id, inclusion: { in: [1], message: "Solo puede existir un registro de configuración" }

  # Class method to get the singleton instance
  def self.instance
    first_or_create!(
      id: 1,
      require_driver_authorization: false,
      customer_visible_pending_pickup: true,
      customer_visible_in_warehouse: true,
      customer_visible_in_transit: true,
      customer_visible_rescheduled: true,
      customer_visible_delivered: true,
      customer_visible_return: true,
      customer_visible_cancelled: true
    )
  rescue ActiveRecord::RecordInvalid
    # En caso de race condition en tests paralelos, intentar obtener el registro existente
    first || create!(
      id: 1,
      require_driver_authorization: false,
      customer_visible_pending_pickup: true,
      customer_visible_in_warehouse: true,
      customer_visible_in_transit: true,
      customer_visible_rescheduled: true,
      customer_visible_delivered: true,
      customer_visible_return: true,
      customer_visible_cancelled: true
    )
  end

  # Convenience method to check if driver authorization is required
  def self.require_driver_authorization?
    instance.require_driver_authorization
  end

  # Update a specific setting
  def self.update_setting(key, value)
    instance.update!(key => value)
  end

  # Check if a specific package status is visible to customers
  # @param status [Symbol, String] The package status (e.g., :delivered, "in_transit")
  # @return [Boolean] true if status should be visible to customers
  def self.status_visible_for_customers?(status)
    status_sym = status.to_s.to_sym

    # Core statuses are ALWAYS visible (cannot be disabled)
    core_statuses = [:pending_pickup, :in_warehouse, :in_transit, :delivered]
    return true if core_statuses.include?(status_sym)

    column_name = "customer_visible_#{status_sym}"

    # Return true if column doesn't exist (backward compatibility)
    return true unless instance.respond_to?(column_name)

    instance.public_send(column_name)
  end

  # Returns array of all customer-visible statuses
  # @return [Array<Symbol>] Array of visible status symbols
  def self.customer_visible_statuses
    Package.statuses.keys.select do |status|
      status_visible_for_customers?(status)
    end
  end
end
