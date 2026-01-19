class AddFieldsToPackages < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:packages, :phone)
      add_column :packages, :phone, :string
    end

    unless column_exists?(:packages, :exchange)
      add_column :packages, :exchange, :boolean, default: false, null: false
    end

    unless column_exists?(:packages, :pickup_date)
      add_column :packages, :pickup_date, :date
    end

    unless index_exists?(:packages, :pickup_date, name: 'index_packages_on_pickup_date')
      add_index :packages, :pickup_date
    end

    unless index_exists?(:packages, :exchange, name: 'index_packages_on_exchange')
      add_index :packages, :exchange
    end
  end
end
