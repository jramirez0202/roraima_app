class AddCustomerFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    # RUT chileno (formato: 12.345.678-9)
    add_column :users, :rut, :string
    add_index :users, :rut, unique: true

    # Teléfono (formato: +569XXXXXXXX)
    add_column :users, :phone, :string
    add_index :users, :phone

    # Nombre de empresa
    add_column :users, :company, :string

    # Estado de la cuenta (activa/inactiva)
    add_column :users, :active, :boolean, default: true, null: false

    # Cargo por envío para customers (CLP)
    add_column :users, :delivery_charge, :decimal, precision: 10, scale: 2, default: 0.0, null: false

    # Índice compuesto para búsquedas por role y estado
    add_index :users, [:role, :active]
  end
end
