class AddShowLogoOnLabelsToUsers < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:users, :show_logo_on_labels)
      add_column :users, :show_logo_on_labels, :boolean, default: true
    end
  end
end
