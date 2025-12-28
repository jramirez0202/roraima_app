class AddAssignmentAuditToPackages < ActiveRecord::Migration[7.1]
  def change
    # Campo para timestamp de asignación
    add_column :packages, :assigned_at, :datetime

    # Campo para usuario que realizó la asignación
    add_reference :packages, :assigned_by,
                  foreign_key: { to_table: :users },
                  index: true

    # Índice compuesto para queries comunes (vista de drivers ordenada por fecha)
    add_index :packages, [:assigned_courier_id, :assigned_at]

    # Migración de datos existentes: llenar assigned_at para paquetes ya asignados
    reversible do |dir|
      dir.up do
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
