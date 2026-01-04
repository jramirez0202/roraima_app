class AddBulkUploadRefToPackages < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:packages, :bulk_upload_id)
      add_reference :packages, :bulk_upload, foreign_key: true, index: true
    end
  end
end
