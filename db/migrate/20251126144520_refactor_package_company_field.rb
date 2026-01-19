class RefactorPackageCompanyField < ActiveRecord::Migration[7.1]
  def up
    # Add new column for company name
    unless column_exists?(:packages, :company_name)
      add_column :packages, :company_name, :string
    end

    # Backfill data: company_name = user's company
    # Note: company column still exists and will be renamed to sender_email
    if column_exists?(:packages, :company_name) && column_exists?(:packages, :company)
      Package.reset_column_information
      Package.where(company_name: nil).find_each do |package|
        package.update_columns(
          company_name: package.user&.company
        )
      end
    end

    # Rename column: company -> sender_email (preserves existing data)
    if column_exists?(:packages, :company) && !column_exists?(:packages, :sender_email)
      rename_column :packages, :company, :sender_email
    end
  end

  def down
    # Rename back
    if column_exists?(:packages, :sender_email) && !column_exists?(:packages, :company)
      rename_column :packages, :sender_email, :company
    end

    # Remove the added column
    if column_exists?(:packages, :company_name)
      remove_column :packages, :company_name
    end
  end
end
