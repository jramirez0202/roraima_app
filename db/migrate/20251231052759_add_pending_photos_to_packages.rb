class AddPendingPhotosToPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :packages, :pending_photos, :boolean, default: false, null: false
    add_column :packages, :photos_uploaded_at, :datetime
    add_column :packages, :photos_confirmed_at, :datetime

    # Índice parcial para consultar paquetes pendientes de fotos
    add_index :packages, :pending_photos, where: "pending_photos = true",
              name: "index_packages_on_pending_photos"

    # Índice compuesto para drivers: estado delivered + pending_photos + courier
    add_index :packages, [:status, :pending_photos, :assigned_courier_id],
              name: "index_packages_on_status_pending_photos_courier"
  end
end
