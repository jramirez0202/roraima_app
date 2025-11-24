class AddShowLogoOnLabelsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :show_logo_on_labels, :boolean, default: true
  end
end
