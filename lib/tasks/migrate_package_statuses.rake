namespace :packages do
  desc "Migrar estados antiguos (active/cancelled) a nuevos estados con tracking"
  task migrate_statuses: :environment do
    puts "Iniciando migración de estados de paquetes..."
    puts "=" * 80

    # Contador de cambios
    migrated_count = 0
    error_count = 0

    Package.find_each do |package|
      begin
        # Solo migrar si no tiene status_history inicializado
        if package.status_history.blank? || package.status_history.empty?
          current_status_value = package.status_before_type_cast

          # Determinar el nuevo estado basado en el valor actual
          case current_status_value
          when 0
            # active (0) -> pendiente_retiro (0)
            # Ya tiene el valor correcto, solo inicializar historial
            new_status = :pendiente_retiro
            reason = "Migración automática desde estado 'active'"

          when 1
            # cancelled (1) -> cancelado (7)
            new_status = :cancelado
            reason = "Migración automática desde estado 'cancelled'"
            package.status = 7  # Cambiar el valor a cancelado

          else
            # Si ya está en uno de los nuevos estados, solo inicializar historial
            new_status = Package.statuses.key(current_status_value)
            reason = "Inicialización de historial"
          end

          # Inicializar status_history con entrada inicial
          package.status_history = [{
            status: new_status.to_s,
            previous_status: nil,
            timestamp: package.created_at.iso8601,
            user_id: package.user_id,
            reason: reason,
            location: nil,
            override: false,
            migrated: true
          }]

          # Si tiene cancelled_at, agregarlo al historial
          if package.cancelled_at.present? && new_status == :cancelado
            package.status_history << {
              status: 'cancelado',
              previous_status: 'pendiente_retiro',
              timestamp: package.cancelled_at.iso8601,
              user_id: package.user_id,
              reason: package.cancellation_reason || "Cancelación (motivo no especificado)",
              location: nil,
              override: false,
              migrated: true
            }
          end

          # Guardar sin validaciones para evitar problemas con datos antiguos
          if package.save(validate: false)
            migrated_count += 1
            print "."
          else
            error_count += 1
            print "E"
            puts "\nError en paquete ID #{package.id}: #{package.errors.full_messages.join(', ')}"
          end
        end

      rescue StandardError => e
        error_count += 1
        puts "\nExcepción en paquete ID #{package.id}: #{e.message}"
      end
    end

    puts "\n"
    puts "=" * 80
    puts "Migración completada!"
    puts "Paquetes migrados: #{migrated_count}"
    puts "Errores: #{error_count}"
    puts "=" * 80

    # Mostrar resumen de estados
    puts "\nResumen de estados actuales:"
    Package.group(:status).count.each do |status, count|
      status_name = Package.statuses.key(status)
      puts "  #{status_name}: #{count} paquetes"
    end
  end

  desc "Verificar integridad de estados después de migración"
  task verify_migration: :environment do
    puts "Verificando integridad de la migración..."
    puts "=" * 80

    total = Package.count
    with_history = Package.where.not(status_history: []).count
    without_history = total - with_history

    puts "Total de paquetes: #{total}"
    puts "Con historial: #{with_history}"
    puts "Sin historial: #{without_history}"

    if without_history > 0
      puts "\n⚠️  Advertencia: #{without_history} paquetes sin historial de estados"
      puts "Ejecuta: rails packages:migrate_statuses"
    else
      puts "\n✓ Todos los paquetes tienen historial inicializado"
    end

    # Verificar estados válidos
    invalid_statuses = []
    Package.find_each do |package|
      unless Package.statuses.keys.include?(package.status)
        invalid_statuses << package.id
      end
    end

    if invalid_statuses.any?
      puts "\n⚠️  Advertencia: #{invalid_statuses.count} paquetes con estados inválidos"
      puts "IDs: #{invalid_statuses.first(10).join(', ')}..."
    else
      puts "✓ Todos los estados son válidos"
    end

    puts "=" * 80
  end
end
