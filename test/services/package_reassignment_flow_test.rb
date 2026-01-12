require 'test_helper'

class PackageReassignmentFlowTest < ActiveSupport::TestCase
  # Test QA: Flujo completo de reasignación de paquete entre drivers
  # Escenario: Admin asigna paquete a driver1, se da cuenta del error, lo desasigna y lo asigna a driver2

  def setup
    # Crear admin
    @admin = User.create!(
      email: 'admin@test.com',
      password: 'password123',
      role: :admin,
      active: true,
      name: 'Admin Test'
    )

    # Crear driver1 (conductor equivocado)
    @driver1 = Driver.create!(
      email: 'driver1@test.com',
      password: 'password123',
      role: :driver,
      active: true,
      name: 'Carlos Rodriguez',
      vehicle_plate: 'AB1234'
    )

    # Crear driver2 (conductor correcto)
    @driver2 = Driver.create!(
      email: 'driver2@test.com',
      password: 'password123',
      role: :driver,
      active: true,
      name: 'Juan Perez',
      vehicle_plate: 'CD5678'
    )

    # Crear customer (dueño del paquete)
    @customer = User.create!(
      email: 'customer@test.com',
      password: 'password123',
      role: :customer,
      active: true,
      name: 'Cliente Test',
      company: 'Empresa Test'
    )

    # Crear región y comuna
    @region = Region.create!(name: 'Región Metropolitana')
    @commune = Commune.create!(name: 'Santiago', region: @region)

    # Crear paquete en estado BODEGA (in_warehouse)
    @package = Package.create!(
      tracking_code: "PKG-#{Time.now.to_i}#{rand(1000..9999)}",
      user: @customer,
      region: @region,
      commune: @commune,
      address: 'Dirección Test 123',
      phone: '+56987654321',
      loading_date: Date.current,
      status: :in_warehouse,
      provider: 'PKG'
    )

    puts "\n" + "="*80
    puts "🧪 TEST QA: FLUJO DE REASIGNACIÓN DE PAQUETE"
    puts "="*80
    puts "Setup completado:"
    puts "  ✓ Admin: #{@admin.email}"
    puts "  ✓ Driver1 (equivocado): #{@driver1.name}"
    puts "  ✓ Driver2 (correcto): #{@driver2.name}"
    puts "  ✓ Customer: #{@customer.email}"
    puts "  ✓ Paquete: #{@package.tracking_code} en estado #{@package.status}"
    puts "-"*80
  end

  test "flujo completo de reasignación: bodega → driver1 → bodega → driver2" do
    # PASO 1: Admin asigna paquete a driver1 (bodega → en camino)
    puts "\n📋 PASO 1: Asignar paquete a Driver1 (Carlos Rodriguez)"
    puts "  Estado inicial: #{@package.status}"
    puts "  Conductor inicial: #{@package.assigned_courier&.name || 'Sin asignar'}"

    service = PackageStatusService.new(@package, @admin)
    result = service.assign_courier(@driver1.id)

    assert result, "Debería poder asignar el paquete a driver1"
    assert_empty service.errors, "No debería haber errores: #{service.errors.join(', ')}"

    @package.reload

    assert_equal 'in_transit', @package.status, "El paquete debería estar en estado 'en camino'"
    assert_equal @driver1.id, @package.assigned_courier_id, "El paquete debería estar asignado a driver1"
    assert_not_nil @package.assigned_at, "Debería tener fecha de asignación"
    assert_equal @admin.id, @package.assigned_by_id, "Debería registrar quién asignó"

    puts "  ✅ Paquete asignado exitosamente a #{@driver1.name}"
    puts "  Estado: #{@package.status}"
    puts "  Conductor: #{@package.assigned_courier.name}"
    puts "  Asignado por: #{@admin.email}"
    puts "  Fecha asignación: #{@package.assigned_at}"

    # PASO 2: Verificar que driver1 NO ha iniciado ruta
    puts "\n📋 PASO 2: Verificar que Driver1 NO ha iniciado ruta"
    assert_not @driver1.on_route?, "Driver1 NO debería tener ruta iniciada"
    puts "  ✅ Driver1 no tiene ruta iniciada (on_route? = false)"
    puts "  Estado de ruta: #{@driver1.route_status}"

    # PASO 3: Admin se da cuenta del error y desasigna el paquete
    puts "\n📋 PASO 3: Admin desasigna el paquete (error detectado)"
    puts "  Admin detecta que el paquete no corresponde a #{@driver1.name}"

    service = PackageStatusService.new(@package, @admin)
    result = service.assign_courier(nil) # nil = desasignar

    assert result, "Debería poder desasignar el paquete"
    assert_empty service.errors, "No debería haber errores: #{service.errors.join(', ')}"

    @package.reload

    assert_equal 'in_warehouse', @package.status, "El paquete debería volver a 'bodega'"
    assert_nil @package.assigned_courier_id, "El paquete NO debería tener conductor asignado"
    assert_nil @package.assigned_at, "La fecha de asignación debería estar limpia"

    puts "  ✅ Paquete desasignado exitosamente"
    puts "  Estado: #{@package.status}"
    puts "  Conductor: Sin asignar"

    # PASO 4: Admin asigna el paquete al conductor correcto (driver2)
    puts "\n📋 PASO 4: Asignar paquete al conductor correcto (Driver2 - Juan Perez)"

    service = PackageStatusService.new(@package, @admin)
    result = service.assign_courier(@driver2.id)

    assert result, "Debería poder asignar el paquete a driver2"
    assert_empty service.errors, "No debería haber errores: #{service.errors.join(', ')}"

    @package.reload

    assert_equal 'in_transit', @package.status, "El paquete debería estar en estado 'en camino'"
    assert_equal @driver2.id, @package.assigned_courier_id, "El paquete debería estar asignado a driver2"
    assert_not_nil @package.assigned_at, "Debería tener fecha de asignación"
    assert_equal @admin.id, @package.assigned_by_id, "Debería registrar quién asignó"

    puts "  ✅ Paquete asignado exitosamente a #{@driver2.name}"
    puts "  Estado: #{@package.status}"
    puts "  Conductor: #{@package.assigned_courier.name}"
    puts "  Asignado por: #{@admin.email}"
    puts "  Fecha asignación: #{@package.assigned_at}"

    # VERIFICACIONES FINALES
    puts "\n📊 VERIFICACIONES FINALES:"
    puts "  ✓ Estado final: #{@package.status} (esperado: in_transit)"
    puts "  ✓ Conductor final: #{@package.assigned_courier.name} (esperado: #{@driver2.name})"
    puts "  ✓ Driver1 quedó sin paquetes asignados: #{@driver1.assigned_packages.count == 0}"
    puts "  ✓ Driver2 tiene 1 paquete asignado: #{@driver2.assigned_packages.count == 1}"

    # Assertions finales
    assert_equal @driver2, @package.assigned_courier, "El conductor final debería ser driver2"
    assert_equal 0, @driver1.assigned_packages.count, "Driver1 no debería tener paquetes asignados"
    assert_equal 1, @driver2.assigned_packages.count, "Driver2 debería tener 1 paquete asignado"

    puts "\n" + "="*80
    puts "✅ TEST COMPLETADO EXITOSAMENTE"
    puts "="*80
  end

  test "no debería permitir desasignar si el driver ya inició ruta" do
    puts "\n" + "="*80
    puts "🧪 TEST QA: BLOQUEO DE DESASIGNACIÓN CON RUTA INICIADA"
    puts "="*80

    # PASO 1: Asignar paquete a driver1
    service = PackageStatusService.new(@package, @admin)
    result = service.assign_courier(@driver1.id)
    assert result, "Debería poder asignar el paquete"

    @package.reload
    puts "  ✓ Paquete asignado a #{@driver1.name}"

    # PASO 2: Driver1 inicia su ruta
    @driver1.update!(route_status: :on_route)
    puts "  ✓ Driver1 inicia su ruta (on_route? = true)"

    # PASO 3: Intentar desasignar (debería FALLAR)
    puts "\n📋 Intentando desasignar con ruta iniciada..."
    service = PackageStatusService.new(@package, @admin)
    result = service.assign_courier(nil)

    assert_not result, "NO debería permitir desasignar con ruta iniciada"
    assert_not_empty service.errors, "Debería haber un error de validación"

    error_message = service.errors.first
    assert_includes error_message, "ya inició su ruta", "El error debería mencionar que la ruta está iniciada"

    @package.reload

    assert_equal 'in_transit', @package.status, "El paquete debería seguir en 'en camino'"
    assert_equal @driver1.id, @package.assigned_courier_id, "El paquete debería seguir asignado a driver1"

    puts "  ✅ Desasignación bloqueada correctamente"
    puts "  Error: #{error_message}"
    puts "  Estado: #{@package.status} (se mantiene)"
    puts "  Conductor: #{@package.assigned_courier.name} (se mantiene)"

    puts "\n" + "="*80
    puts "✅ TEST DE BLOQUEO COMPLETADO EXITOSAMENTE"
    puts "="*80
  end

  test "cambio masivo a bodega debería desasignar conductor automáticamente" do
    puts "\n" + "="*80
    puts "🧪 TEST QA: DESASIGNACIÓN AUTOMÁTICA AL CAMBIAR A BODEGA"
    puts "="*80

    # PASO 1: Asignar paquete a driver1
    service = PackageStatusService.new(@package, @admin)
    service.assign_courier(@driver1.id)
    @package.reload

    puts "  Estado inicial: #{@package.status}"
    puts "  Conductor inicial: #{@package.assigned_courier.name}"

    # PASO 2: Cambiar estado a bodega (debería desasignar automáticamente)
    puts "\n📋 Cambiando estado a 'bodega'..."
    service = PackageStatusService.new(@package, @admin)
    result = service.change_status(:in_warehouse, reason: "Test de desasignación automática", override: true)

    assert result, "Debería poder cambiar a bodega"
    assert_empty service.errors, "No debería haber errores: #{service.errors.join(', ')}"

    @package.reload

    assert_equal 'in_warehouse', @package.status, "El paquete debería estar en 'bodega'"
    assert_nil @package.assigned_courier_id, "El conductor debería haberse desasignado automáticamente"
    assert_nil @package.assigned_at, "La fecha de asignación debería estar limpia"

    puts "  ✅ Cambio exitoso con desasignación automática"
    puts "  Estado final: #{@package.status}"
    puts "  Conductor final: Sin asignar (automático)"

    puts "\n" + "="*80
    puts "✅ TEST DE DESASIGNACIÓN AUTOMÁTICA COMPLETADO"
    puts "="*80
  end
end
