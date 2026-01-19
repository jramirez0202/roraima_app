class CreateZones < ActiveRecord::Migration[7.1]
  def change
    unless table_exists?(:zones)
      create_table :zones do |t|
        t.string :name, null: false
        t.references :region, foreign_key: true
        t.jsonb :communes, default: []
        t.boolean :active, default: true

        t.timestamps
      end
    end

    unless index_exists?(:zones, :name, name: 'index_zones_on_name')
      add_index :zones, :name, unique: true
    end

    unless index_exists?(:zones, :active, name: 'index_zones_on_active')
      add_index :zones, :active
    end
  end
end
