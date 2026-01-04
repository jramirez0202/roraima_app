class FixRutUniqueIndex < ActiveRecord::Migration[7.1]
  def up
    if column_exists?(:users, :rut)
      # Convertir RUTs vacíos existentes en NULL
      execute "UPDATE users SET rut = NULL WHERE rut = ''"

      # Eliminar el índice único actual si existe
      if index_exists?(:users, :rut, name: 'index_users_on_rut')
        remove_index :users, :rut
      end

      # Crear un índice parcial que solo valida unicidad cuando rut no es NULL
      # Esto permite múltiples usuarios con rut = NULL
      unless index_exists?(:users, :rut, where: "rut IS NOT NULL")
        add_index :users, :rut, unique: true, where: "rut IS NOT NULL"
      end
    end
  end

  def down
    if column_exists?(:users, :rut)
      # Revertir: eliminar índice parcial y recrear índice único simple
      if index_exists?(:users, :rut, where: "rut IS NOT NULL")
        remove_index :users, :rut
      end

      unless index_exists?(:users, :rut, name: 'index_users_on_rut')
        add_index :users, :rut, unique: true
      end
    end
  end
end
