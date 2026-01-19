class AddAmountToPackages < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:packages, :amount)
      add_column :packages, :amount, :decimal, precision: 10, scale: 2, default: 0, null: false
    end
  end
end
