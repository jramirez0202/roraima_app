class AddCustomerFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    # RUT chileno (formato: 12.345.678-9)
    unless column_exists?(:users, :rut)
      add_column :users, :rut, :string
    end

    unless index_exists?(:users, :rut, name: 'index_users_on_rut')
      add_index :users, :rut, unique: true
    end

    # Teléfono (formato: +569XXXXXXXX)
    unless column_exists?(:users, :phone)
      add_column :users, :phone, :string
    end

    unless index_exists?(:users, :phone, name: 'index_users_on_phone')
      add_index :users, :phone
    end

    # Nombre de empresa
    unless column_exists?(:users, :company)
      add_column :users, :company, :string
    end

    # Estado de la cuenta (activa/inactiva)
    unless column_exists?(:users, :active)
      add_column :users, :active, :boolean, default: true, null: false
    end

    # Cargo por envío para customers (CLP)
    unless column_exists?(:users, :delivery_charge)
      add_column :users, :delivery_charge, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    end

    # Índice compuesto para búsquedas por role y estado
    unless index_exists?(:users, [:role, :active], name: 'index_users_on_role_and_active')
      add_index :users, [:role, :active]
    end
  end
end
