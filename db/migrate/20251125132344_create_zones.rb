class CreateZones < ActiveRecord::Migration[7.1]
  def change
    create_table :zones do |t|
      t.string :name, null: false
      t.references :region, foreign_key: true
      t.jsonb :communes, default: []
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :zones, :name, unique: true
    add_index :zones, :active
  end
end
