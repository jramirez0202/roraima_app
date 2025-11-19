class AddUserToPackages < ActiveRecord::Migration[7.1]
  def change
    add_reference :packages, :user, foreign_key: true, null: true
  end
end
