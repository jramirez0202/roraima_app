class AddForcedCloseFieldsToRoutes < ActiveRecord::Migration[7.1]
  def change
    add_column :routes, :closed_by_id, :integer
    add_column :routes, :forced_close_reason, :text
    add_column :routes, :forced_closed_at, :datetime

    # Índice para buscar rutas cerradas forzadamente
    add_index :routes, :closed_by_id
    add_index :routes, :forced_closed_at

    # Foreign key para auditoría (quién cerró la ruta)
    add_foreign_key :routes, :users, column: :closed_by_id
  end
end
