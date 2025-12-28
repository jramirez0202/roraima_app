class RenamePickupDateToLoadingDateInPackages < ActiveRecord::Migration[7.1]
  def change
    # Renombrar pickup_date a loading_date
    rename_column :packages, :pickup_date, :loading_date

    # Renombrar los índices que usan pickup_date si existen
    # Nota: PostgreSQL puede renombrar automáticamente los índices al renombrar la columna
    if index_exists?(:packages, :pickup_date, name: 'index_packages_on_pickup_date')
      rename_index :packages, 'index_packages_on_pickup_date', 'index_packages_on_loading_date'
    end

    if index_exists?(:packages, [:status, :pickup_date], name: 'index_packages_on_status_and_pickup_date')
      rename_index :packages, 'index_packages_on_status_and_pickup_date', 'index_packages_on_status_and_loading_date'
    end
  end
end
