class AddDriverFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :vehicle_plate, :string
    add_column :users, :vehicle_model, :string
    add_column :users, :vehicle_capacity, :integer
    add_reference :users, :assigned_zone, foreign_key: { to_table: :zones }

    add_index :users, :vehicle_plate, unique: true, where: "vehicle_plate IS NOT NULL"
  end
end
