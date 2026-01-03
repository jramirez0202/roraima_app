class AddReceiverDetailsToPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :packages, :receiver_name, :string, limit: 30
    add_column :packages, :receiver_observations, :text
  end
end
