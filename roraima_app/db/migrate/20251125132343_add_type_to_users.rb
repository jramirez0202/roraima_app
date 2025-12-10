class AddTypeToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :type, :string
    add_index :users, :type
  end
end
