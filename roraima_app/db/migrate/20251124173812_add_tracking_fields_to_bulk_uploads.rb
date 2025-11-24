class AddTrackingFieldsToBulkUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :bulk_uploads, :processed_count, :integer, default: 0, null: false
    add_column :bulk_uploads, :current_row, :integer
    add_column :bulk_uploads, :started_at, :datetime
  end
end
