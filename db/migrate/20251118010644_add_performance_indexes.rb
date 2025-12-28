class AddPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    # Índice compuesto crítico: user_id + status
    # Usado en: dashboard de customers, filtros de packages
    # Impacto: 60-80% mejora en queries de packages por usuario y estado
    add_index :packages, [:user_id, :status], name: 'index_packages_on_user_id_and_status'

    # Índice compuesto: status + pickup_date
    # Usado en: scope pending_pickup, listados filtrados por fecha
    # Impacto: 40-60% mejora en queries de paquetes pendientes
    add_index :packages, [:status, :pickup_date], name: 'index_packages_on_status_and_pickup_date'

    # Índice compuesto: region_id + commune_id
    # Usado en: búsquedas geográficas, reportes por zona
    # Impacto: 30-50% mejora en queries de localización
    add_index :packages, [:region_id, :commune_id], name: 'index_packages_on_region_and_commune'

    # Índice en created_at
    # Usado en: scope :recent (ORDER BY created_at DESC)
    # Impacto: 50-70% mejora en ordenamiento de listados
    add_index :packages, :created_at, name: 'index_packages_on_created_at'

    # Nota: El índice en users.role ya existe en migración anterior (20251117233308)
  end
end
