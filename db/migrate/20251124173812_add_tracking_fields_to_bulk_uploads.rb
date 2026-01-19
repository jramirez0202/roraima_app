class AddTrackingFieldsToBulkUploads < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:bulk_uploads, :processed_count)
      add_column :bulk_uploads, :processed_count, :integer, default: 0, null: false
    end

    unless column_exists?(:bulk_uploads, :current_row)
      add_column :bulk_uploads, :current_row, :integer
    end

    unless column_exists?(:bulk_uploads, :started_at)
      add_column :bulk_uploads, :started_at, :datetime
    end
  end
end
