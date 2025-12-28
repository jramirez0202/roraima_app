namespace :bulk_upload do
  desc "Setup communes for bulk upload testing"
  task setup_communes: :environment do
    puts "🔍 Verificando Región Metropolitana..."

    region = Region.find_or_create_by!(name: 'Región Metropolitana')
    puts "✅ Región encontrada: #{region.name} (ID: #{region.id})"

    communes = [
      'Providencia',
      'Las Condes',
      'La Florida',
      'Santiago',
      'Maipú',
      'Ñuñoa',
      'La Reina',
      'Macul',
      'Peñalolén',
      'Vitacura',
      'Lo Barnechea',
      'La Cisterna',
      'El Bosque',
      'San Miguel',
      'San Joaquín',
      'La Granja',
      'La Pintana',
      'San Ramón',
      'Puente Alto',
      'Pirque',
      'San José de Maipo',
      'Colina',
      'Lampa',
      'Til Til',
      'San Bernardo',
      'Buin',
      'Paine',
      'Calera de Tango',
      'Pudahuel',
      'Quilicura',
      'Renca',
      'Conchalí',
      'Huechuraba',
      'Independencia',
      'Recoleta',
      'Cerro Navia',
      'Lo Prado',
      'Quinta Normal',
      'Estación Central',
      'Cerrillos',
      'Pedro Aguirre Cerda',
      'Lo Espejo'
    ]

    puts "\n📝 Creando/verificando comunas..."
    created = 0
    existing = 0

    communes.each do |commune_name|
      commune = Commune.find_or_create_by!(name: commune_name, region: region)
      if commune.previously_new_record?
        created += 1
        puts "  ✨ Creada: #{commune_name}"
      else
        existing += 1
        puts "  ✓ Ya existe: #{commune_name}"
      end
    end

    puts "\n" + "="*50
    puts "📊 Resumen:"
    puts "  Comunas creadas: #{created}"
    puts "  Comunas existentes: #{existing}"
    puts "  Total: #{communes.size}"
    puts "="*50

    puts "\n✅ ¡Listo! Ahora puedes usar la carga masiva con estas comunas."
    puts "\nEjemplo de CSV válido:"
    puts "FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA"
    puts "2025-01-15,ORD-001,Juan Pérez,912345678,Av. Providencia 123,Providencia,Paquete,15000,NO,Test Corp"
  end

  desc "Check last bulk upload errors"
  task check_errors: :environment do
    bulk = BulkUpload.last

    if bulk.nil?
      puts "❌ No hay bulk uploads en la base de datos"
      exit
    end

    puts "📊 BulkUpload ##{bulk.id}"
    puts "="*50
    puts "Usuario: #{bulk.user.email}"
    puts "Estado: #{bulk.status}"
    puts "Total filas: #{bulk.total_rows}"
    puts "Exitosas: #{bulk.successful_rows}"
    puts "Fallidas: #{bulk.failed_rows}"
    puts "Procesado: #{bulk.processed_at}"
    puts "="*50

    if bulk.error_details.any?
      puts "\n❌ Errores encontrados:"
      puts "-"*50
      bulk.formatted_errors.each_with_index do |error, index|
        puts "#{index + 1}. #{error}"
      end
    else
      puts "\n✅ No hay errores registrados"
    end
  end
end
