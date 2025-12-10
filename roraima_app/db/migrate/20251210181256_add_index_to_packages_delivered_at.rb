class AddIndexToPackagesDeliveredAt < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # Composite index for Driver#today_deliveries optimization
    # Allows fast queries filtering by assigned_courier_id AND delivered_at
    add_index :packages,
              [:assigned_courier_id, :delivered_at],
              algorithm: :concurrently,
              name: 'index_packages_on_assigned_courier_and_delivered_at',
              comment: 'Optimizes Driver#today_deliveries queries (QA audit fix)'
  end
end
