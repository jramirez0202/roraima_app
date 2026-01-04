class AddRoleToUsers < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:users, :role)
      add_column :users, :role, :integer, default: 1, null: false
    end

    unless index_exists?(:users, :role, name: 'index_users_on_role')
      add_index :users, :role
    end
  end
end
