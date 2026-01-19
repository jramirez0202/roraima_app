class CreateCommunes < ActiveRecord::Migration[7.1]
  def change
    unless table_exists?(:communes)
      create_table :communes do |t|
        t.string :name, null: false
        t.references :region, null: false, foreign_key: true
        t.timestamps
      end
    end

    unless index_exists?(:communes, :name, name: 'index_communes_on_name')
      add_index :communes, :name
    end

    unless index_exists?(:communes, [:region_id, :name], name: 'index_communes_on_region_id_and_name')
      add_index :communes, [:region_id, :name], unique: true
    end
  end
end