class AddFieldsToPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :packages, :phone, :string
    add_column :packages, :exchange, :boolean, default: false, null: false
    add_column :packages, :pickup_date, :date

    add_index :packages, :pickup_date
    add_index :packages, :exchange
  end
end
