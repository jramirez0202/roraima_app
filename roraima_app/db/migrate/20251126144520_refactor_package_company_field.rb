class RefactorPackageCompanyField < ActiveRecord::Migration[7.1]
  def up
    # Add new column for company name
    add_column :packages, :company_name, :string

    # Backfill data: company_name = user's company
    # Note: company column still exists and will be renamed to sender_email
    Package.reset_column_information
    Package.find_each do |package|
      package.update_columns(
        company_name: package.user&.company
      )
    end

    # Rename column: company -> sender_email (preserves existing data)
    rename_column :packages, :company, :sender_email
  end

  def down
    # Rename back
    rename_column :packages, :sender_email, :company

    # Remove the added column
    remove_column :packages, :company_name
  end
end
