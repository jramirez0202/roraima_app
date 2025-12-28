class AddCustomerVisibleStatusesToSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :settings, :customer_visible_pending_pickup, :boolean, default: true, null: false
    add_column :settings, :customer_visible_in_warehouse, :boolean, default: true, null: false
    add_column :settings, :customer_visible_in_transit, :boolean, default: true, null: false
    add_column :settings, :customer_visible_rescheduled, :boolean, default: true, null: false
    add_column :settings, :customer_visible_delivered, :boolean, default: true, null: false
    add_column :settings, :customer_visible_picked_up, :boolean, default: true, null: false
    add_column :settings, :customer_visible_return, :boolean, default: true, null: false
    add_column :settings, :customer_visible_cancelled, :boolean, default: true, null: false
  end
end
