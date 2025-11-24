class AddTrackingFieldsToPackages < ActiveRecord::Migration[7.1]
  def change
    # Campos para tracking de estados
    add_column :packages, :previous_status, :integer
    add_column :packages, :status_history, :jsonb, default: []
    add_column :packages, :location, :string
    add_column :packages, :attempts_count, :integer, default: 0

    # Referencia al courier/repartidor asignado
    add_reference :packages, :assigned_courier, foreign_key: { to_table: :users }, index: true

    # Prueba de entrega/retiro (firma, foto, etc)
    add_column :packages, :proof, :text

    # Reprogramación
    add_column :packages, :reprogramed_to, :datetime
    add_column :packages, :reprogram_motive, :text

    # Timestamps por evento
    add_column :packages, :picked_at, :datetime
    add_column :packages, :shipped_at, :datetime
    add_column :packages, :delivered_at, :datetime

    # Override manual por admin
    add_column :packages, :admin_override, :boolean, default: false

    # Índices para optimizar queries
    add_index :packages, [:status, :assigned_courier_id]
    add_index :packages, [:status, :pickup_date]
  end
end
