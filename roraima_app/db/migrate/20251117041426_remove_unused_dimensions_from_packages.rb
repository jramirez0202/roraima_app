class RemoveUnusedDimensionsFromPackages < ActiveRecord::Migration[7.1]
  def change
    remove_column :packages, :weight, :decimal
    remove_column :packages, :dimension_x, :decimal
    remove_column :packages, :dimension_y, :decimal
  end
end
