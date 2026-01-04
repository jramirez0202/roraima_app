class AddUserToPackages < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:packages, :user_id)
      add_reference :packages, :user, foreign_key: true, null: true
    end
  end
end
