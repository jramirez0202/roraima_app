class CreateBulkUploads < ActiveRecord::Migration[7.1]
  def change
    unless table_exists?(:bulk_uploads)
      create_table :bulk_uploads do |t|
        t.references :user, null: false, foreign_key: true
        t.integer :status, default: 0, null: false
        t.integer :total_rows, default: 0
        t.integer :successful_rows, default: 0
        t.integer :failed_rows, default: 0
        t.jsonb :error_details, default: []
        t.datetime :processed_at

        t.timestamps
      end
    end

    unless index_exists?(:bulk_uploads, :status, name: 'index_bulk_uploads_on_status')
      add_index :bulk_uploads, :status
    end

    unless index_exists?(:bulk_uploads, :created_at, name: 'index_bulk_uploads_on_created_at')
      add_index :bulk_uploads, :created_at
    end
  end
end
