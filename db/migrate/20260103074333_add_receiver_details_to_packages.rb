class AddReceiverDetailsToPackages < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:packages, :receiver_name)
      add_column :packages, :receiver_name, :string, limit: 30
    end

    unless column_exists?(:packages, :receiver_observations)
      add_column :packages, :receiver_observations, :text
    end
  end
end
