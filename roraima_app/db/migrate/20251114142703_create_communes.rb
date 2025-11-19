class CreateCommunes < ActiveRecord::Migration[7.1]
  def change
    create_table :communes do |t|
      t.string :name, null: false
      t.references :region, null: false, foreign_key: true
      t.timestamps
    end
    
    add_index :communes, :name
    add_index :communes, [:region_id, :name], unique: true
  end
end