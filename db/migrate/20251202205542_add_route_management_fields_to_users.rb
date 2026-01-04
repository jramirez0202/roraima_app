class AddRouteManagementFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    # Admin authorization flag
    unless column_exists?(:users, :ready_for_route)
      add_column :users, :ready_for_route, :boolean, default: false, null: false
    end

    # Route lifecycle enum: 0=inactive, 1=ready, 2=on_route, 3=completed
    unless column_exists?(:users, :route_status)
      add_column :users, :route_status, :integer, default: 0, null: false
    end

    # Audit timestamps
    unless column_exists?(:users, :route_started_at)
      add_column :users, :route_started_at, :datetime
    end

    unless column_exists?(:users, :route_ended_at)
      add_column :users, :route_ended_at, :datetime
    end

    # Performance indexes
    unless index_exists?(:users, :route_status, name: 'index_users_on_route_status')
      add_index :users, :route_status
    end

    unless index_exists?(:users, :ready_for_route, name: 'index_users_on_ready_for_route')
      add_index :users, :ready_for_route
    end

    unless index_exists?(:users, [:type, :route_status], name: 'index_users_on_type_and_route_status')
      add_index :users, [:type, :route_status], name: 'index_users_on_type_and_route_status'
    end
  end
end
