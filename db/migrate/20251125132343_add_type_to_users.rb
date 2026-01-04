class AddTypeToUsers < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:users, :type)
      add_column :users, :type, :string
    end

    unless index_exists?(:users, :type, name: 'index_users_on_type')
      add_index :users, :type
    end
  end
end
