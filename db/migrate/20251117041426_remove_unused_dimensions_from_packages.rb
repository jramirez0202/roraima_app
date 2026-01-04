class RemoveUnusedDimensionsFromPackages < ActiveRecord::Migration[7.1]
  def change
    if column_exists?(:packages, :weight)
      remove_column :packages, :weight, :decimal
    end

    if column_exists?(:packages, :dimension_x)
      remove_column :packages, :dimension_x, :decimal
    end

    if column_exists?(:packages, :dimension_y)
      remove_column :packages, :dimension_y, :decimal
    end
  end
end
