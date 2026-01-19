class AddForcedCloseFieldsToRoutes < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:routes, :closed_by_id)
      add_column :routes, :closed_by_id, :integer
    end

    unless column_exists?(:routes, :forced_close_reason)
      add_column :routes, :forced_close_reason, :text
    end

    unless column_exists?(:routes, :forced_closed_at)
      add_column :routes, :forced_closed_at, :datetime
    end

    # Índice para buscar rutas cerradas forzadamente
    unless index_exists?(:routes, :closed_by_id, name: 'index_routes_on_closed_by_id')
      add_index :routes, :closed_by_id
    end

    unless index_exists?(:routes, :forced_closed_at, name: 'index_routes_on_forced_closed_at')
      add_index :routes, :forced_closed_at
    end

    # Foreign key para auditoría (quién cerró la ruta)
    unless foreign_key_exists?(:routes, :users, column: :closed_by_id)
      add_foreign_key :routes, :users, column: :closed_by_id
    end
  end
end
