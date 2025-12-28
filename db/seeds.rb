

puts "🌍 Creando regiones y comunas de Chile..."

regions_data = {
  "Región de Arica y Parinacota" => [
    "Arica", "Camarones", "Putre", "General Lagos"
  ],
  
  "Región de Tarapacá" => [
    "Iquique", "Alto Hospicio", "Pozo Almonte", "Camiña", 
    "Colchane", "Huara", "Pica"
  ],
  
  "Región de Antofagasta" => [
    "Antofagasta", "Mejillones", "Sierra Gorda", "Taltal",
    "Calama", "Ollagüe", "San Pedro de Atacama",
    "Tocopilla", "María Elena"
  ],
  
  "Región de Atacama" => [
    "Copiapó", "Caldera", "Tierra Amarilla",
    "Chañaral", "Diego de Almagro",
    "Vallenar", "Alto del Carmen", "Freirina", "Huasco"
  ],
  
  "Región de Coquimbo" => [
    "La Serena", "Coquimbo", "Andacollo", "La Higuera", "Paiguano", "Vicuña",
    "Illapel", "Canela", "Los Vilos", "Salamanca",
    "Ovalle", "Combarbalá", "Monte Patria", "Punitaqui", "Río Hurtado"
  ],
  
  "Región de Valparaíso" => [
    "Valparaíso", "Casablanca", "Concón", "Juan Fernández", "Puchuncaví",
    "Quintero", "Viña del Mar",
    "Isla de Pascua",
    "Los Andes", "Calle Larga", "Rinconada", "San Esteban",
    "La Ligua", "Cabildo", "Papudo", "Petorca", "Zapallar",
    "Quillota", "Calera", "Hijuelas", "La Cruz", "Nogales",
    "San Antonio", "Algarrobo", "Cartagena", "El Quisco", "El Tabo", "Santo Domingo",
    "San Felipe", "Catemu", "Llaillay", "Panquehue", "Putaendo", "Santa María",
    "Quilpué", "Limache", "Olmué", "Villa Alemana"
  ],
  
  "Región Metropolitana" => [
    "Santiago", "Cerrillos", "Cerro Navia", "Conchalí", "El Bosque",
    "Estación Central", "Huechuraba", "Independencia", "La Cisterna",
    "La Florida", "La Granja", "La Pintana", "La Reina", "Las Condes",
    "Lo Barnechea", "Lo Espejo", "Lo Prado", "Macul", "Maipú",
    "Ñuñoa", "Pedro Aguirre Cerda", "Peñalolén", "Providencia",
    "Pudahuel", "Quilicura", "Quinta Normal", "Recoleta", "Renca",
    "San Joaquín", "San Miguel", "San Ramón", "Vitacura",
    "Puente Alto", "Pirque", "San José de Maipo",
    "Colina", "Lampa", "Tiltil",
    "San Bernardo", "Buin", "Calera de Tango", "Paine",
    "Melipilla", "Alhué", "Curacaví", "María Pinto", "San Pedro",
    "Talagante", "El Monte", "Isla de Maipo", "Padre Hurtado", "Peñaflor"
  ],
  
  "Región de O'Higgins" => [
    "Rancagua", "Codegua", "Coinco", "Coltauco", "Doñihue",
    "Graneros", "Las Cabras", "Machalí", "Malloa", "Mostazal",
    "Olivar", "Peumo", "Pichidegua", "Quinta de Tilcoco", "Rengo",
    "Requínoa", "San Vicente",
    "Pichilemu", "La Estrella", "Litueche", "Marchihue", "Navidad", "Paredones",
    "San Fernando", "Chépica", "Chimbarongo", "Lolol", "Nancagua",
    "Palmilla", "Peralillo", "Placilla", "Pumanque", "Santa Cruz"
  ],
  
  "Región del Maule" => [
    "Talca", "Constitución", "Curepto", "Empedrado", "Maule",
    "Pelarco", "Pencahue", "Río Claro", "San Clemente", "San Rafael",
    "Cauquenes", "Chanco", "Pelluhue",
    "Curicó", "Hualañé", "Licantén", "Molina", "Rauco", "Romeral",
    "Sagrada Familia", "Teno", "Vichuquén",
    "Linares", "Colbún", "Longaví", "Parral", "Retiro", "San Javier",
    "Villa Alegre", "Yerbas Buenas"
  ],
  
  "Región de Ñuble" => [
    "Chillán", "Bulnes", "Chillán Viejo", "El Carmen", "Pemuco",
    "Pinto", "Quillón", "San Ignacio", "Yungay",
    "Cobquecura", "Coelemu", "Ninhue", "Portezuelo", "Quirihue",
    "Ránquil", "Treguaco",
    "Coihueco", "Ñiquén", "San Carlos", "San Fabián", "San Nicolás"
  ],
  
  "Región del Biobío" => [
    "Concepción", "Coronel", "Chiguayante", "Florida", "Hualqui",
    "Lota", "Penco", "San Pedro de la Paz", "Santa Juana",
    "Talcahuano", "Tomé", "Hualpén",
    "Lebu", "Arauco", "Cañete", "Contulmo", "Curanilahue",
    "Los Álamos", "Tirúa",
    "Los Ángeles", "Antuco", "Cabrero", "Laja", "Mulchén",
    "Nacimiento", "Negrete", "Quilaco", "Quilleco", "San Rosendo",
    "Santa Bárbara", "Tucapel", "Yumbel", "Alto Biobío"
  ],
  
  "Región de La Araucanía" => [
    "Temuco", "Carahue", "Cunco", "Curarrehue", "Freire",
    "Galvarino", "Gorbea", "Lautaro", "Loncoche", "Melipeuco",
    "Nueva Imperial", "Padre Las Casas", "Perquenco", "Pitrufquén",
    "Pucón", "Saavedra", "Teodoro Schmidt", "Toltén", "Vilcún",
    "Villarrica", "Cholchol",
    "Angol", "Collipulli", "Curacautín", "Ercilla", "Lonquimay",
    "Los Sauces", "Lumaco", "Purén", "Renaico", "Traiguén", "Victoria"
  ],
  
  "Región de Los Ríos" => [
    "Valdivia", "Corral", "Lanco", "Los Lagos", "Máfil",
    "Mariquina", "Paillaco", "Panguipulli",
    "La Unión", "Futrono", "Lago Ranco", "Río Bueno"
  ],
  
  "Región de Los Lagos" => [
    "Puerto Montt", "Calbuco", "Cochamó", "Fresia", "Frutillar",
    "Los Muermos", "Llanquihue", "Maullín", "Puerto Varas",
    "Castro", "Ancud", "Chonchi", "Curaco de Vélez", "Dalcahue",
    "Puqueldón", "Queilén", "Quellón", "Quemchi", "Quinchao",
    "Osorno", "Puerto Octay", "Purranque", "Puyehue", "Río Negro",
    "San Juan de la Costa", "San Pablo",
    "Chaitén", "Futaleufú", "Hualaihué", "Palena"
  ],
  
  "Región de Aysén" => [
    "Coyhaique", "Lago Verde",
    "Aysén", "Cisnes", "Guaitecas",
    "Cochrane", "O'Higgins", "Tortel",
    "Chile Chico", "Río Ibáñez"
  ],
  
  "Región de Magallanes" => [
    "Punta Arenas", "Laguna Blanca", "Río Verde", "San Gregorio",
    "Cabo de Hornos", "Antártica",
    "Porvenir", "Primavera", "Timaukel",
    "Natales", "Torres del Paine"
  ]
}

# Crear regiones y comunas
regions_data.each do |region_name, communes|
  region = Region.find_or_create_by!(name: region_name)
  
  communes.each do |commune_name|
    Commune.find_or_create_by!(name: commune_name, region: region)
  end
  
  puts "✅ #{region_name}: #{communes.count} comunas"
end

puts "\n📊 Resumen:"
puts "   Regiones: #{Region.count}"
puts "   Comunas: #{Commune.count}"

# Crear zonas de reparto (solo para Región Metropolitana)
puts "\n🗺️  Creando zonas de reparto..."

metropolitan_region = Region.find_by(name: "Región Metropolitana")
metropolitan_communes = metropolitan_region.communes

# Zona Norte: comunas del norte de Santiago
zona_norte = Zone.find_or_create_by!(name: "Zona Norte RM") do |z|
  z.region = metropolitan_region
  z.communes = metropolitan_communes.where(name: [
    "Huechuraba", "Conchalí", "Independencia", "Recoleta",
    "Quilicura", "Colina", "Lampa"
  ]).pluck(:id)
  z.active = true
end
puts "   ✅ Zona Norte RM: #{zona_norte.commune_names.count} comunas"

# Zona Centro: comunas del centro de Santiago
zona_centro = Zone.find_or_create_by!(name: "Zona Centro RM") do |z|
  z.region = metropolitan_region
  z.communes = metropolitan_communes.where(name: [
    "Santiago", "Providencia", "Las Condes", "Vitacura",
    "Ñuñoa", "La Reina", "Estación Central", "Quinta Normal"
  ]).pluck(:id)
  z.active = true
end
puts "   ✅ Zona Centro RM: #{zona_centro.commune_names.count} comunas"

# Zona Sur: comunas del sur de Santiago
zona_sur = Zone.find_or_create_by!(name: "Zona Sur RM") do |z|
  z.region = metropolitan_region
  z.communes = metropolitan_communes.where(name: [
    "La Florida", "Puente Alto", "La Pintana", "San Bernardo",
    "El Bosque", "La Granja", "San Ramón", "Pedro Aguirre Cerda"
  ]).pluck(:id)
  z.active = true
end
puts "   ✅ Zona Sur RM: #{zona_sur.commune_names.count} comunas"

# Zona Oeste: comunas del oeste de Santiago
zona_oeste = Zone.find_or_create_by!(name: "Zona Oeste RM") do |z|
  z.region = metropolitan_region
  z.communes = metropolitan_communes.where(name: [
    "Maipú", "Pudahuel", "Cerrillos", "Lo Prado",
    "Renca", "Cerro Navia", "Peñalolén"
  ]).pluck(:id)
  z.active = true
end
puts "   ✅ Zona Oeste RM: #{zona_oeste.commune_names.count} comunas"

puts "\n📊 Zonas creadas: #{Zone.count}"

# Crear usuarios
puts "\n👥 Creando usuarios..."

# Crear admin
admin = User.find_or_create_by!(email: 'admin@paqueteria.com') do |u|
  u.password = '123456'
  u.role = :admin
  u.admin = true
  u.rut = "11.111.111-1"
  u.phone = "+56900000000"
  u.company = "Administración"
  u.delivery_charge = 0
  u.active = true
end
puts "   ✅ Admin creado: admin@paqueteria.com"

# Crear customers con información completa
customer1 = User.find_or_create_by!(email: "customer1@example.com") do |u|
  u.password = 'password123'
  u.role = :customer
  u.admin = false
  u.rut = "12.345.678-9"
  u.phone = "+56987654321"
  u.company = "Empresa ABC S.A."
  u.delivery_charge = 5000
  u.active = true
end
puts "   ✅ Customer 1 creado: customer1@example.com (#{customer1.company})"

customer2 = User.find_or_create_by!(email: "customer2@example.com") do |u|
  u.password = 'password123'
  u.role = :customer
  u.admin = false
  u.rut = "23.456.789-0"
  u.phone = "+56912345678"
  u.company = "Comercial XYZ Ltda."
  u.delivery_charge = 4500
  u.active = true
end
puts "   ✅ Customer 2 creado: customer2@example.com (#{customer2.company})"

customer3 = User.find_or_create_by!(email: "customer3@example.com") do |u|
  u.password = 'password123'
  u.role = :customer
  u.admin = false
  u.rut = "34.567.890-1"
  u.phone = "+56998765432"
  u.company = "Logística 123 SpA"
  u.delivery_charge = 6000
  u.active = true
end
puts "   ✅ Customer 3 creado: customer3@example.com (#{customer3.company})"

# Crear un customer inactivo para testing
customer_inactive = User.find_or_create_by!(email: "inactive@example.com") do |u|
  u.password = 'password123'
  u.role = :customer
  u.admin = false
  u.rut = "45.678.901-2"
  u.phone = "+56911112222"
  u.company = "Empresa Inactiva S.A."
  u.delivery_charge = 3000
  u.active = false
end
puts "   ✅ Customer inactivo creado: inactive@example.com (cuenta desactivada)"

# Crear drivers con STI
puts "\n🚗 Creando conductores..."

driver1 = Driver.find_or_create_by!(email: "driver1@example.com") do |u|
  u.password = 'password123'
  u.name = "Juan Pérez"
  u.role = :driver
  u.admin = false
  u.rut = "56.789.012-3"
  u.phone = "+56922223333"
  u.active = true
  u.vehicle_plate = "AABB12"
  u.vehicle_model = "Toyota Hiace 2020"
  u.vehicle_capacity = 1500
  u.assigned_zone = zona_norte
end
puts "   ✅ Driver 1 creado: driver1@example.com (#{driver1.vehicle_model}, Zona: #{driver1.assigned_zone.name})"

driver2 = Driver.find_or_create_by!(email: "driver2@example.com") do |u|
  u.password = 'password123'
  u.name = "María González"
  u.role = :driver
  u.admin = false
  u.rut = "67.890.123-4"
  u.phone = "+56933334444"
  u.active = true
  u.vehicle_plate = "CCDD34"
  u.vehicle_model = "Hyundai H100 2021"
  u.vehicle_capacity = 1200
  u.assigned_zone = zona_centro
end
puts "   ✅ Driver 2 creado: driver2@example.com (#{driver2.vehicle_model}, Zona: #{driver2.assigned_zone.name})"

driver3 = Driver.find_or_create_by!(email: "driver3@example.com") do |u|
  u.password = 'password123'
  u.name = "Carlos Rodríguez"
  u.role = :driver
  u.admin = false
  u.rut = "78.901.234-5"
  u.phone = "+56944445555"
  u.active = true
  u.vehicle_plate = "EEFF56"
  u.vehicle_model = "Chevrolet N300 2019"
  u.vehicle_capacity = 800
  u.assigned_zone = zona_sur
end
puts "   ✅ Driver 3 creado: driver3@example.com (#{driver3.vehicle_model}, Zona: #{driver3.assigned_zone.name})"

puts "\n✅ #{User.count} usuarios creados:"
puts "   • #{User.admin.count} Administrador(es)"
puts "   • #{User.customer.count} Cliente(s)"
puts "   • #{Driver.count} Conductor(es)"

# Crear paquetes de prueba
puts "\n📦 Creando paquetes de prueba..."

# IMPORTANTE: El sistema solo opera en Región Metropolitana
metropolitan_region = Region.find_by(name: "Región Metropolitana")
metropolitan_communes = metropolitan_region.communes.to_a

# Crear 5 paquetes para customer1
5.times do |i|
  commune = metropolitan_communes.sample

  Package.create!(
    customer_name: "Cliente de Customer1 #{i + 1}",
    sender_email: customer1.email,
    company_name: customer1.company,
    phone: "+569#{sprintf('%08d', rand(10000000..99999999))}",
    address: "Calle #{['Las Rosas', 'Los Olivos', 'Alameda', 'Providencia'].sample} #{rand(100..9999)}",
    region_id: metropolitan_region.id,
    commune_id: commune.id,
    description: "Paquete de prueba para customer1",
    exchange: [true, false, false, false].sample,
    loading_date: Date.today + rand(0..14).days,
    user_id: customer1.id
  )
end
puts "   ✅ 5 paquetes creados para customer1@example.com en Región Metropolitana"

# Crear 3 paquetes para customer2
3.times do |i|
  commune = metropolitan_communes.sample

  Package.create!(
    customer_name: "Cliente de Customer2 #{i + 1}",
    sender_email: customer2.email,
    company_name: customer2.company,
    phone: "+569#{sprintf('%08d', rand(10000000..99999999))}",
    address: "Av. #{['Kennedy', 'Apoquindo', 'Vicuña Mackenna'].sample} #{rand(100..9999)}",
    region_id: metropolitan_region.id,
    commune_id: commune.id,
    description: "Paquete de prueba para customer2",
    exchange: [true, false, false].sample,
    loading_date: Date.today + rand(0..7).days,
    user_id: customer2.id
  )
end
puts "   ✅ 3 paquetes creados para customer2@example.com en Región Metropolitana"

# Crear 2 paquetes para customer3
2.times do |i|
  commune = metropolitan_communes.sample

  Package.create!(
    customer_name: "Cliente de Customer3 #{i + 1}",
    sender_email: customer3.email,
    company_name: customer3.company,
    phone: "+569#{sprintf('%08d', rand(10000000..99999999))}",
    address: "Pasaje #{['Los Aromos', 'Las Acacias', 'El Bosque'].sample} #{rand(10..999)}",
    region_id: metropolitan_region.id,
    commune_id: commune.id,
    description: "Paquete de prueba para customer3",
    exchange: false,
    loading_date: Date.today + rand(1..5).days,
    user_id: customer3.id
  )
end
puts "   ✅ 2 paquetes creados para customer3@example.com en Región Metropolitana"

puts "\n✅ #{Package.count} paquetes creados en total (solo customers pueden tener paquetes)"
puts "\n🎉 Seeds completados exitosamente!"
puts "\n" + "="*60
puts "🔑 CREDENCIALES DE ACCESO"
puts "="*60
puts "\n👤 ADMIN:"
puts "   Email: admin@paqueteria.com"
puts "   Password: password123"
puts "   Role: Administrador (gestiona todos los paquetes)"

puts "\n👤 CUSTOMER 1:"
puts "   Email: customer1@example.com"
puts "   Password: password123"
puts "   Empresa: #{customer1.company}"
puts "   RUT: #{customer1.rut}"
puts "   Teléfono: #{customer1.phone}"
puts "   Cobro por envío: #{customer1.formatted_delivery_charge}"
puts "   Paquetes: #{customer1.packages.count}"

puts "\n👤 CUSTOMER 2:"
puts "   Email: customer2@example.com"
puts "   Password: password123"
puts "   Empresa: #{customer2.company}"
puts "   RUT: #{customer2.rut}"
puts "   Teléfono: #{customer2.phone}"
puts "   Cobro por envío: #{customer2.formatted_delivery_charge}"
puts "   Paquetes: #{customer2.packages.count}"

puts "\n👤 CUSTOMER 3:"
puts "   Email: customer3@example.com"
puts "   Password: password123"
puts "   Empresa: #{customer3.company}"
puts "   RUT: #{customer3.rut}"
puts "   Teléfono: #{customer3.phone}"
puts "   Cobro por envío: #{customer3.formatted_delivery_charge}"
puts "   Paquetes: #{customer3.packages.count}"

puts "\n👤 CUSTOMER INACTIVO (para testing):"
puts "   Email: inactive@example.com"
puts "   Password: password123"
puts "   Estado: INACTIVO (no puede iniciar sesión)"
puts "   Empresa: #{customer_inactive.company}"

puts "\n🚗 DRIVER 1:"
puts "   Email: driver1@example.com"
puts "   Password: password123"
puts "   RUT: #{driver1.rut}"
puts "   Teléfono: #{driver1.phone}"
puts "   Vehículo: #{driver1.vehicle_model}"
puts "   Patente: #{driver1.vehicle_plate}"
puts "   Capacidad: #{driver1.vehicle_capacity} kg"
puts "   Zona asignada: #{driver1.assigned_zone.name}"

puts "\n🚗 DRIVER 2:"
puts "   Email: driver2@example.com"
puts "   Password: password123"
puts "   RUT: #{driver2.rut}"
puts "   Teléfono: #{driver2.phone}"
puts "   Vehículo: #{driver2.vehicle_model}"
puts "   Patente: #{driver2.vehicle_plate}"
puts "   Capacidad: #{driver2.vehicle_capacity} kg"
puts "   Zona asignada: #{driver2.assigned_zone.name}"

puts "\n🚗 DRIVER 3:"
puts "   Email: driver3@example.com"
puts "   Password: password123"
puts "   RUT: #{driver3.rut}"
puts "   Teléfono: #{driver3.phone}"
puts "   Vehículo: #{driver3.vehicle_model}"
puts "   Patente: #{driver3.vehicle_plate}"
puts "   Capacidad: #{driver3.vehicle_capacity} kg"
puts "   Zona asignada: #{driver3.assigned_zone.name}"

puts "\n" + "="*60
puts "📊 RESUMEN:"
puts "   • #{User.admin.count} Administrador(es)"
puts "   • #{User.customer.active.count} Clientes activos"
puts "   • #{User.customer.inactive.count} Cliente(s) inactivo(s)"
puts "   • #{Driver.count} Conductor(es) con STI"
puts "   • #{Zone.count} Zonas de reparto"
puts "   • #{Package.count} Paquetes"
puts "="*60