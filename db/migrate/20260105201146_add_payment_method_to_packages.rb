class AddPaymentMethodToPackages < ActiveRecord::Migration[7.1]
  def change
    # Agregar columna payment_method si no existe
    # 0 = cash (efectivo - default), 1 = transfer (transferencia)
    unless column_exists?(:packages, :payment_method)
      add_column :packages, :payment_method, :integer, default: 0, null: false
    end
  end
end
