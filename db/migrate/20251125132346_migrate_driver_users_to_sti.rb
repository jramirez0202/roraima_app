class MigrateDriverUsersToSti < ActiveRecord::Migration[7.1]
  def up
    # Asignar type='Driver' a users con role=driver
    User.where(role: :driver).update_all(type: 'Driver')

    # Asignar type='User' a admin y customer explícitamente
    User.where(role: [:admin, :customer]).update_all(type: 'User')
  end

  def down
    # Rollback: quitar type
    User.where(type: 'Driver').update_all(type: nil)
    User.update_all(type: nil)
  end
end
