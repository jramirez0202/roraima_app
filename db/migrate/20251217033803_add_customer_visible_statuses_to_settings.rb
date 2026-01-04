class AddCustomerVisibleStatusesToSettings < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:settings, :customer_visible_pending_pickup)
      add_column :settings, :customer_visible_pending_pickup, :boolean, default: true, null: false
    end

    unless column_exists?(:settings, :customer_visible_in_warehouse)
      add_column :settings, :customer_visible_in_warehouse, :boolean, default: true, null: false
    end

    unless column_exists?(:settings, :customer_visible_in_transit)
      add_column :settings, :customer_visible_in_transit, :boolean, default: true, null: false
    end

    unless column_exists?(:settings, :customer_visible_rescheduled)
      add_column :settings, :customer_visible_rescheduled, :boolean, default: true, null: false
    end

    unless column_exists?(:settings, :customer_visible_delivered)
      add_column :settings, :customer_visible_delivered, :boolean, default: true, null: false
    end

    unless column_exists?(:settings, :customer_visible_picked_up)
      add_column :settings, :customer_visible_picked_up, :boolean, default: true, null: false
    end

    unless column_exists?(:settings, :customer_visible_return)
      add_column :settings, :customer_visible_return, :boolean, default: true, null: false
    end

    unless column_exists?(:settings, :customer_visible_cancelled)
      add_column :settings, :customer_visible_cancelled, :boolean, default: true, null: false
    end
  end
end
