class RemovePickedUpFromSettings < ActiveRecord::Migration[7.1]
  def change
    if column_exists?(:settings, :customer_visible_picked_up)
      remove_column :settings, :customer_visible_picked_up, :boolean
    end
  end
end
