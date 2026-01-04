class AddTrigramIndexToPackagesTrackingCode < ActiveRecord::Migration[7.1]
  def up
    # Habilitar extensión pg_trgm para búsquedas ILIKE rápidas
    unless extension_enabled?('pg_trgm')
      enable_extension 'pg_trgm'
    end

    # Crear índice GIN en tracking_code para búsquedas ILIKE con wildcards
    # Esto permite búsqueda rápida por primeros, últimos o cualquier dígito
    unless index_exists?(:packages, :tracking_code, name: 'index_packages_on_tracking_code_trigram')
      add_index :packages, :tracking_code,
                using: :gin,
                opclass: :gin_trgm_ops,
                name: 'index_packages_on_tracking_code_trigram',
                comment: 'Trigram index for fast ILIKE searches on tracking_code'
    end
  end

  def down
    if index_exists?(:packages, :tracking_code, name: 'index_packages_on_tracking_code_trigram')
      remove_index :packages, name: 'index_packages_on_tracking_code_trigram'
    end
    # No deshabilitamos pg_trgm por si otras tablas lo usan
  end
end
