class AddRegionAndCommuneToPackages < ActiveRecord::Migration[7.1]
  def change
    if column_exists?(:packages, :city)
      remove_column :packages, :city, :string
    end

    if column_exists?(:packages, :region)
      remove_column :packages, :region, :string
    end

    unless column_exists?(:packages, :region_id)
      add_reference :packages, :region, foreign_key: true
    end

    unless column_exists?(:packages, :commune_id)
      add_reference :packages, :commune, foreign_key: true
    end
  end
end