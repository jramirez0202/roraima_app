class RemoveDeliveryDateFromPackages < ActiveRecord::Migration[7.1]
  def change
    remove_column :packages, :delivery_date, :date if column_exists?(:packages, :delivery_date)

    # También eliminar el índice si existe
    if index_exists?(:packages, [:status, :delivery_date], name: 'index_packages_on_status_and_delivery_date')
      remove_index :packages, name: 'index_packages_on_status_and_delivery_date'
    end
  end
end
