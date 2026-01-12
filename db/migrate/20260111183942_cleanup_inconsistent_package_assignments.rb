class CleanupInconsistentPackageAssignments < ActiveRecord::Migration[7.1]
  def up
    # Encuentra paquetes con conductor asignado pero NO en estado 'in_transit'
    # Esta inconsistencia ocurre cuando falla el cambio de estado pero la asignación ya se guardó
    inconsistent_packages = Package.where.not(assigned_courier_id: nil)
                                   .where.not(status: Package.statuses[:in_transit])

    count = inconsistent_packages.count

    if count > 0
      puts "🔍 Encontrados #{count} paquetes con conductor asignado pero NO en estado 'En Camino'"
      puts "   Limpiando datos inconsistentes..."

      # Log los paquetes antes de limpiar
      inconsistent_packages.each do |pkg|
        driver_name = pkg.assigned_courier&.name || pkg.assigned_courier&.email || "ID: #{pkg.assigned_courier_id}"
        puts "   - PKG #{pkg.tracking_code}: Estado '#{pkg.status}' con driver '#{driver_name}'"
      end

      # Limpiar: establecer assigned_courier_id a nil
      inconsistent_packages.update_all(
        assigned_courier_id: nil,
        assigned_at: nil,
        assigned_by_id: nil
      )

      puts "✅ #{count} paquetes limpiados correctamente"
    else
      puts "✅ No se encontraron paquetes inconsistentes. Base de datos OK."
    end
  end

  def down
    # No hay forma de revertir esta limpieza de datos
    # Los datos incorrectos ya fueron removidos
    puts "⚠️  No se puede revertir la limpieza de datos inconsistentes"
  end
end
