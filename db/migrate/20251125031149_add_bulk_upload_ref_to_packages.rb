class AddBulkUploadRefToPackages < ActiveRecord::Migration[7.1]
  def change
    add_reference :packages, :bulk_upload, foreign_key: true, index: true
  end
end
