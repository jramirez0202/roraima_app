class AddRouteManagementFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    # Admin authorization flag
    add_column :users, :ready_for_route, :boolean, default: false, null: false

    # Route lifecycle enum: 0=inactive, 1=ready, 2=on_route, 3=completed
    add_column :users, :route_status, :integer, default: 0, null: false

    # Audit timestamps
    add_column :users, :route_started_at, :datetime
    add_column :users, :route_ended_at, :datetime

    # Performance indexes
    add_index :users, :route_status
    add_index :users, :ready_for_route
    add_index :users, [:type, :route_status], name: 'index_users_on_type_and_route_status'
  end
end
