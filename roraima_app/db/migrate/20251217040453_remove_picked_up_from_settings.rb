class RemovePickedUpFromSettings < ActiveRecord::Migration[7.1]
  def change
    remove_column :settings, :customer_visible_picked_up, :boolean
  end
end
