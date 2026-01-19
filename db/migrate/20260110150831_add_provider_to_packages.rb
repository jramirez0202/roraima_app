class AddProviderToPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :packages, :provider, :string, default: 'PKG', null: false
    add_index :packages, :provider
    add_index :packages, [:provider, :tracking_code], unique: true
  end
end
