class CreatePackages < ActiveRecord::Migration[7.1]
  def change
    create_table :packages do |t|
      t.string :customer_name
      t.string :company
      t.decimal :weight
      t.decimal :dimension_x
      t.decimal :dimension_y
      t.text :address
      t.string :city
      t.string :region
      t.text :description

      t.timestamps
    end
  end
end
