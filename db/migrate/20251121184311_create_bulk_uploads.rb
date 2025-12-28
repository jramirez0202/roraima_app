class CreateBulkUploads < ActiveRecord::Migration[7.1]
  def change
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

    add_index :bulk_uploads, :status
    add_index :bulk_uploads, :created_at
  end
end
