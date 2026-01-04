class AddAssignmentAuditToPackages < ActiveRecord::Migration[7.1]
  def change
    # Campo para timestamp de asignación
    unless column_exists?(:packages, :assigned_at)
      add_column :packages, :assigned_at, :datetime
    end

    # Campo para usuario que realizó la asignación
    unless column_exists?(:packages, :assigned_by_id)
      add_reference :packages, :assigned_by,
                    foreign_key: { to_table: :users },
                    index: true
    end

    # Índice compuesto para queries comunes (vista de drivers ordenada por fecha)
    unless index_exists?(:packages, [:assigned_courier_id, :assigned_at], name: 'index_packages_on_assigned_courier_id_and_assigned_at')
      add_index :packages, [:assigned_courier_id, :assigned_at]
    end

    # Migración de datos existentes: llenar assigned_at para paquetes ya asignados
    reversible do |dir|
      dir.up do
        if column_exists?(:packages, :assigned_at) && column_exists?(:packages, :assigned_courier_id)
          execute <<-SQL
            UPDATE packages
            SET assigned_at = created_at
            WHERE assigned_courier_id IS NOT NULL
              AND assigned_at IS NULL
          SQL
        end
      end
    end
  end
end
