class FixRutUniqueIndex < ActiveRecord::Migration[7.1]
  def up
    # Convertir RUTs vacíos existentes en NULL
    execute "UPDATE users SET rut = NULL WHERE rut = ''"

    # Eliminar el índice único actual
    remove_index :users, :rut

    # Crear un índice parcial que solo valida unicidad cuando rut no es NULL
    # Esto permite múltiples usuarios con rut = NULL
    add_index :users, :rut, unique: true, where: "rut IS NOT NULL"
  end

  def down
    # Revertir: eliminar índice parcial y recrear índice único simple
    remove_index :users, :rut
    add_index :users, :rut, unique: true
  end
end
