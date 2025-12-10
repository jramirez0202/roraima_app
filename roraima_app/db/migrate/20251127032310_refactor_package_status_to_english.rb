class RefactorPackageStatusToEnglish < ActiveRecord::Migration[7.1]
  def up
    # Mapping from Spanish to English
    # The integer values stay the same, only the enum names change
    status_mapping = {
      'pendiente_retiro' => 'pending_pickup',
      'en_bodega' => 'in_warehouse',
      'en_camino' => 'in_transit',
      'reprogramado' => 'rescheduled',
      'entregado' => 'delivered',
      'retirado' => 'picked_up',
      'devolucion' => 'return',
      'cancelado' => 'cancelled'
    }

    # Update status_history JSONB field
    # This updates the 'status' and 'previous_status' keys within the JSONB arrays
    Package.find_each do |package|
      next unless package.status_history.present?

      updated_history = package.status_history.map do |entry|
        entry['status'] = status_mapping[entry['status']] if entry['status'] && status_mapping[entry['status']]
        entry['previous_status'] = status_mapping[entry['previous_status']] if entry['previous_status'] && status_mapping[entry['previous_status']]
        entry
      end

      package.update_column(:status_history, updated_history)
    end

    say "Updated status_history for all packages"
  end

  def down
    # Mapping from English back to Spanish
    status_mapping = {
      'pending_pickup' => 'pendiente_retiro',
      'in_warehouse' => 'en_bodega',
      'in_transit' => 'en_camino',
      'rescheduled' => 'reprogramado',
      'delivered' => 'entregado',
      'picked_up' => 'retirado',
      'return' => 'devolucion',
      'cancelled' => 'cancelado'
    }

    # Revert status_history JSONB field
    Package.find_each do |package|
      next unless package.status_history.present?

      reverted_history = package.status_history.map do |entry|
        entry['status'] = status_mapping[entry['status']] if entry['status'] && status_mapping[entry['status']]
        entry['previous_status'] = status_mapping[entry['previous_status']] if entry['previous_status'] && status_mapping[entry['previous_status']]
        entry
      end

      package.update_column(:status_history, reverted_history)
    end

    say "Reverted status_history for all packages"
  end
end
