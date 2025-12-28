class AddRegionAndCommuneToPackages < ActiveRecord::Migration[7.1]
  def change

    remove_column :packages, :city, :string
    remove_column :packages, :region, :string
    
    add_reference :packages, :region, foreign_key: true
    add_reference :packages, :commune, foreign_key: true
  end
end