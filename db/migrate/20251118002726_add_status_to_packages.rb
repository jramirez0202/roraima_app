class AddStatusToPackages < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:packages, :status)
      add_column :packages, :status, :integer, default: 0, null: false
    end

    unless column_exists?(:packages, :cancelled_at)
      add_column :packages, :cancelled_at, :datetime
    end

    unless column_exists?(:packages, :cancellation_reason)
      add_column :packages, :cancellation_reason, :text
    end

    unless index_exists?(:packages, :status, name: 'index_packages_on_status')
      add_index :packages, :status
    end
  end
end
