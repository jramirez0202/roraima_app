# frozen_string_literal: true

class Setting < ApplicationRecord
  # Singleton pattern - only one settings record should exist
  validates :id, inclusion: { in: [1], message: "Solo puede existir un registro de configuración" }

  # Class method to get the singleton instance
  def self.instance
    first_or_create!(id: 1, require_driver_authorization: false)
  rescue ActiveRecord::RecordInvalid
    # En caso de race condition en tests paralelos, intentar obtener el registro existente
    first || create!(id: 1, require_driver_authorization: false)
  end

  # Convenience method to check if driver authorization is required
  def self.require_driver_authorization?
    instance.require_driver_authorization
  end

  # Update a specific setting
  def self.update_setting(key, value)
    instance.update!(key => value)
  end
end
