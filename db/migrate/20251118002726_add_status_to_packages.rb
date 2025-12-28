class AddStatusToPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :packages, :status, :integer, default: 0, null: false
    add_column :packages, :cancelled_at, :datetime
    add_column :packages, :cancellation_reason, :text

    add_index :packages, :status
  end
end
