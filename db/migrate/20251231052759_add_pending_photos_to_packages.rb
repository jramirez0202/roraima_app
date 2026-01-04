class AddPendingPhotosToPackages < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:packages, :pending_photos)
      add_column :packages, :pending_photos, :boolean, default: false, null: false
    end

    unless column_exists?(:packages, :photos_uploaded_at)
      add_column :packages, :photos_uploaded_at, :datetime
    end

    unless column_exists?(:packages, :photos_confirmed_at)
      add_column :packages, :photos_confirmed_at, :datetime
    end

    # Índice parcial para consultar paquetes pendientes de fotos
    unless index_exists?(:packages, :pending_photos, name: "index_packages_on_pending_photos")
      add_index :packages, :pending_photos, where: "pending_photos = true",
                name: "index_packages_on_pending_photos"
    end

    # Índice compuesto para drivers: estado delivered + pending_photos + courier
    unless index_exists?(:packages, [:status, :pending_photos, :assigned_courier_id], name: "index_packages_on_status_pending_photos_courier")
      add_index :packages, [:status, :pending_photos, :assigned_courier_id],
                name: "index_packages_on_status_pending_photos_courier"
    end
  end
end
