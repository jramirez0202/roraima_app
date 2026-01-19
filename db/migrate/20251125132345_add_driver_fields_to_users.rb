class AddDriverFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:users, :vehicle_plate)
      add_column :users, :vehicle_plate, :string
    end

    unless column_exists?(:users, :vehicle_model)
      add_column :users, :vehicle_model, :string
    end

    unless column_exists?(:users, :vehicle_capacity)
      add_column :users, :vehicle_capacity, :integer
    end

    unless column_exists?(:users, :assigned_zone_id)
      add_reference :users, :assigned_zone, foreign_key: { to_table: :zones }
    end

    unless index_exists?(:users, :vehicle_plate, where: "vehicle_plate IS NOT NULL")
      add_index :users, :vehicle_plate, unique: true, where: "vehicle_plate IS NOT NULL"
    end
  end
end
