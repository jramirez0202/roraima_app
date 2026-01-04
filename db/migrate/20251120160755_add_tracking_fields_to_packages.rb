class AddTrackingFieldsToPackages < ActiveRecord::Migration[7.1]
  def change
    # Campos para tracking de estados
    unless column_exists?(:packages, :previous_status)
      add_column :packages, :previous_status, :integer
    end

    unless column_exists?(:packages, :status_history)
      add_column :packages, :status_history, :jsonb, default: []
    end

    unless column_exists?(:packages, :location)
      add_column :packages, :location, :string
    end

    unless column_exists?(:packages, :attempts_count)
      add_column :packages, :attempts_count, :integer, default: 0
    end

    # Referencia al courier/repartidor asignado
    unless column_exists?(:packages, :assigned_courier_id)
      add_reference :packages, :assigned_courier, foreign_key: { to_table: :users }, index: true
    end

    # Prueba de entrega/retiro (firma, foto, etc)
    unless column_exists?(:packages, :proof)
      add_column :packages, :proof, :text
    end

    # Reprogramación
    unless column_exists?(:packages, :reprogramed_to)
      add_column :packages, :reprogramed_to, :datetime
    end

    unless column_exists?(:packages, :reprogram_motive)
      add_column :packages, :reprogram_motive, :text
    end

    # Timestamps por evento
    unless column_exists?(:packages, :picked_at)
      add_column :packages, :picked_at, :datetime
    end

    unless column_exists?(:packages, :shipped_at)
      add_column :packages, :shipped_at, :datetime
    end

    unless column_exists?(:packages, :delivered_at)
      add_column :packages, :delivered_at, :datetime
    end

    # Override manual por admin
    unless column_exists?(:packages, :admin_override)
      add_column :packages, :admin_override, :boolean, default: false
    end

    # Índices para optimizar queries
    unless index_exists?(:packages, [:status, :assigned_courier_id], name: 'index_packages_on_status_and_assigned_courier_id')
      add_index :packages, [:status, :assigned_courier_id]
    end

    unless index_exists?(:packages, [:status, :pickup_date], name: 'index_packages_on_status_and_pickup_date')
      add_index :packages, [:status, :pickup_date]
    end
  end
end
