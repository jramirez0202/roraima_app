class CreateRoutes < ActiveRecord::Migration[7.1]
  def change
    unless table_exists?(:routes)
      create_table :routes do |t|
        # Foreign key to driver (users table with STI)
        t.bigint :driver_id, null: false

        # Route lifecycle timestamps
        t.datetime :started_at, null: false
        t.datetime :ended_at

        # Business metrics
        t.integer :packages_delivered, default: 0, null: false

        # Route status enum: active (in progress), completed
        t.integer :status, default: 0, null: false

        t.timestamps
      end
    end

    # Performance indexes
    unless index_exists?(:routes, :driver_id, name: 'index_routes_on_driver_id')
      add_index :routes, :driver_id
    end

    unless index_exists?(:routes, :status, name: 'index_routes_on_status')
      add_index :routes, :status
    end

    unless index_exists?(:routes, [:driver_id, :started_at], name: 'index_routes_on_driver_and_started')
      add_index :routes, [:driver_id, :started_at], name: 'index_routes_on_driver_and_started'
    end

    unless index_exists?(:routes, [:driver_id, :status], name: 'index_routes_on_driver_and_status')
      add_index :routes, [:driver_id, :status], name: 'index_routes_on_driver_and_status'
    end

    # Foreign key constraint
    unless foreign_key_exists?(:routes, :users, column: :driver_id)
      add_foreign_key :routes, :users, column: :driver_id
    end
  end
end
