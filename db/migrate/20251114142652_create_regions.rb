class CreateRegions < ActiveRecord::Migration[7.1]
  def change
    unless table_exists?(:regions)
      create_table :regions do |t|
        t.string :name, null: false
        t.timestamps
      end
    end

    unless index_exists?(:regions, :name, name: 'index_regions_on_name')
      add_index :regions, :name, unique: true
    end
  end
end