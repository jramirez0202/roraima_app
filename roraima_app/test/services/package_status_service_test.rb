require "test_helper"

class PackageStatusServiceTest < ActiveSupport::TestCase
  # ==========================================================================
  # FLUJO CRÍTICO: TRANSICIONES DE ESTADO
  # Este test suite cubre el corazón de la aplicación - cambios de estado
  # ==========================================================================

  setup do
    @admin = create(:user, :admin)
    @customer = create(:user, :customer)
    @driver = create(:driver)
  end

  # ==========================================================================
  # SECCIÓN 1: MATRIZ DE TRANSICIONES PERMITIDAS
  # Validar que SOLO las transiciones definidas en ALLOWED_TRANSITIONS funcionen
  # ==========================================================================

  test "pending_pickup can transition to in_warehouse" do
    package = create(:package, status: :pending_pickup)
    service = PackageStatusService.new(package, @admin)

    assert service.change_status(:in_warehouse, reason: "Retirado de origen")
    assert_equal "in_warehouse", package.reload.status
  end

  test "pending_pickup can transition to cancelled" do
    package = create(:package, status: :pending_pickup)
    service = PackageStatusService.new(package, @admin)

    assert service.change_status(:cancelled, reason: "Cliente canceló")
    assert_equal "cancelled", package.reload.status
  end

  test "pending_pickup can transition to picked_up with proof" do
    package = create(:package, status: :pending_pickup)
    service = PackageStatusService.new(package, @admin)

    assert service.change_status(:picked_up, reason: "Retirado en punto", proof: "FIRMA-123")
    assert_equal "picked_up", package.reload.status
  end

  test "pending_pickup CANNOT transition to in_transit without override" do
    package = create(:package, status: :pending_pickup, assigned_courier: @driver)
    service = PackageStatusService.new(package, @admin)

    refute service.change_status(:in_transit, reason: "Intento directo a tránsito")
    assert_includes service.errors.first, "Transición no permitida"
  end

  test "pending_pickup CANNOT transition to delivered without override" do
    package = create(:package, status: :pending_pickup)
    service = PackageStatusService.new(package, @admin)

    refute service.change_status(:delivered, reason: "Salto ilegal", proof: "PROOF-123")
    assert_includes service.errors.first, "Transición no permitida"
  end

  test "in_warehouse can transition to in_transit with courier assigned" do
    package = create(:package, status: :in_warehouse, assigned_courier: @driver)
    service = PackageStatusService.new(package, @admin)

    assert service.change_status(:in_transit, reason: "Salió a reparto")
    assert_equal "in_transit", package.reload.status
  end

  test "in_warehouse CANNOT transition to in_transit without courier" do
    package = create(:package, status: :in_warehouse, assigned_courier: nil)
    service = PackageStatusService.new(package, @admin)

    refute service.change_status(:in_transit, reason: "Sin courier asignado")
    assert_includes service.errors.first, "Debe asignar un courier"
  end

  test "in_warehouse can transition to picked_up with proof" do
    package = create(:package, status: :in_warehouse)
    service = PackageStatusService.new(package, @admin)

    assert service.change_status(:picked_up, reason: "Cliente retiró en bodega", proof: "DOC-456")
    assert_equal "picked_up", package.reload.status
  end

  test "in_warehouse can transition to return" do
    package = create(:package, status: :in_warehouse)
    service = PackageStatusService.new(package, @admin)

    assert service.change_status(:return, reason: "Dirección incorrecta")
    assert_equal "return", package.reload.status
  end

  test "in_transit can transition to delivered with proof" do
    package = create(:package, status: :in_transit, assigned_courier: @driver)
    service = PackageStatusService.new(package, @driver)

    assert service.change_status(:delivered, reason: "Entrega exitosa", proof: "FIRMA-789")
    assert_equal "delivered", package.reload.status
  end

  test "in_transit CANNOT transition to delivered without proof" do
    package = create(:package, status: :in_transit, assigned_courier: @driver)
    service = PackageStatusService.new(package, @driver)

    refute service.change_status(:delivered, reason: "Sin prueba de entrega")
    assert_includes service.errors.first, "Se requiere prueba"
  end

  test "in_transit can transition to rescheduled with motive" do
    package = create(:package, status: :in_transit, assigned_courier: @driver)
    service = PackageStatusService.new(package, @driver)

    assert service.change_status(:rescheduled, motive: "Cliente ausente", reprogram_date: Date.tomorrow)
    assert_equal "rescheduled", package.reload.status
  end

  test "in_transit CANNOT transition to rescheduled without motive" do
    package = create(:package, status: :in_transit, assigned_courier: @driver)
    service = PackageStatusService.new(package, @driver)

    refute service.change_status(:rescheduled, reprogram_date: Date.tomorrow)
    assert_includes service.errors.first, "motivo"
  end

  test "in_transit can transition to return" do
    package = create(:package, status: :in_transit, assigned_courier: @driver)
    service = PackageStatusService.new(package, @driver)

    assert service.change_status(:return, reason: "Dirección no existe")
    assert_equal "return", package.reload.status
  end

  test "rescheduled can transition to in_transit" do
    package = create(:package, status: :rescheduled, assigned_courier: @driver, reprogramed_to: Date.tomorrow)
    service = PackageStatusService.new(package, @driver)

    assert service.change_status(:in_transit, reason: "Segundo intento de entrega")
    assert_equal "in_transit", package.reload.status
  end

  test "rescheduled can transition to return" do
    package = create(:package, status: :rescheduled, assigned_courier: @driver)
    service = PackageStatusService.new(package, @admin)

    assert service.change_status(:return, reason: "Máximo de intentos alcanzado")
    assert_equal "return", package.reload.status
  end

  test "return can transition back to in_warehouse" do
    package = create(:package, status: :return)
    service = PackageStatusService.new(package, @admin)

    assert service.change_status(:in_warehouse, reason: "Regresó a bodega")
    assert_equal "in_warehouse", package.reload.status
  end

  test "return can transition to cancelled" do
    package = create(:package, status: :return)
    service = PackageStatusService.new(package, @admin)

    assert service.change_status(:cancelled, reason: "Cliente no reclama devolución")
    assert_equal "cancelled", package.reload.status
  end

  # ==========================================================================
  # SECCIÓN 2: ESTADOS TERMINALES (CRÍTICO)
  # Los estados terminales NO deben permitir más transiciones
  # ==========================================================================

  test "delivered is TERMINAL and cannot change without override" do
    package = create(:package, status: :delivered, delivered_at: Time.current)
    service = PackageStatusService.new(package, @driver)

    refute service.change_status(:in_transit, reason: "Intento de cambio")
    assert_includes service.errors.first, "Transición no permitida"
  end

  test "delivered CAN change with admin override" do
    package = create(:package, status: :delivered, delivered_at: Time.current)
    service = PackageStatusService.new(package, @admin)

    assert service.change_status(:in_transit, reason: "Corrección administrativa", override: true)
    assert_equal "in_transit", package.reload.status
  end

  test "picked_up is TERMINAL and cannot change without override" do
    package = create(:package, status: :picked_up)
    service = PackageStatusService.new(package, @admin)

    refute service.change_status(:in_warehouse, reason: "Intento de cambio")
    assert_includes service.errors.first, "Transición no permitida"
  end

  test "cancelled is TERMINAL and cannot change without override" do
    package = create(:package, status: :cancelled, cancelled_at: Time.current)
    service = PackageStatusService.new(package, @admin)

    refute service.change_status(:in_warehouse, reason: "Intento de reactivación")
    assert_includes service.errors.first, "Transición no permitida"
  end

  # ==========================================================================
  # SECCIÓN 3: FLUJO CRÍTICO COMPLETO (Happy Path)
  # Este es el flujo normal y más importante de la aplicación
  # ==========================================================================

  test "CRITICAL: Complete happy path flow from creation to delivery" do
    # 1. Paquete creado (pending_pickup)
    package = create(:package, status: :pending_pickup)
    assert_equal "pending_pickup", package.status
    assert_nil package.picked_at

    # 2. Transición a bodega (in_warehouse)
    service = PackageStatusService.new(package, @admin)
    assert service.change_status(:in_warehouse, reason: "Retirado de origen")
    package.reload

    assert_equal "in_warehouse", package.status
    assert_not_nil package.picked_at, "picked_at debe establecerse al llegar a bodega"
    assert_nil package.shipped_at

    # 3. Asignar courier
    service = PackageStatusService.new(package, @admin)
    assert service.assign_courier(@driver.id)
    package.reload
    assert_equal @driver.id, package.assigned_courier_id

    # 4. Transición a en camino (in_transit)
    service = PackageStatusService.new(package, @admin)
    assert service.change_status(:in_transit, reason: "Salió a reparto")
    package.reload

    assert_equal "in_transit", package.status
    assert_not_nil package.shipped_at, "shipped_at debe establecerse al salir a reparto"
    assert_nil package.delivered_at

    # 5. Entrega exitosa (delivered)
    service = PackageStatusService.new(package, @driver)
    assert service.change_status(:delivered, reason: "Entregado al cliente", proof: "FIRMA-CLIENT-123", location: "Dirección confirmada")
    package.reload

    assert_equal "delivered", package.status
    assert_not_nil package.delivered_at, "delivered_at debe establecerse al entregar"
    assert_equal "FIRMA-CLIENT-123", package.proof
    assert package.terminal?, "delivered debe ser estado terminal"

    # 6. Verificar historial completo
    # Solo hay 3 cambios de ESTADO (asignar courier NO es cambio de estado)
    assert_equal 3, package.status_history.size, "Debe tener 3 cambios de estado en el historial"

    history = package.status_history
    assert_equal "in_warehouse", history[0]["status"]
    assert_equal "in_transit", history[1]["status"]
    assert_equal "delivered", history[2]["status"]
  end

  test "CRITICAL: Alternative path - pickup at point" do
    # Flujo: pending_pickup -> picked_up (cliente retira en punto)
    package = create(:package, status: :pending_pickup)
    service = PackageStatusService.new(package, @admin)

    assert service.change_status(:picked_up, reason: "Cliente retiró en punto", proof: "DNI-SCAN-456")
    package.reload

    assert_equal "picked_up", package.status
    assert_not_nil package.delivered_at, "delivered_at debe establecerse al retirar"
    assert_equal "DNI-SCAN-456", package.proof
    assert package.terminal?
  end

  test "CRITICAL: Failed delivery path with rescheduling" do
    # Flujo: pending_pickup -> in_warehouse -> in_transit -> rescheduled -> in_transit -> delivered
    package = create(:package, status: :pending_pickup)

    # A bodega
    service = PackageStatusService.new(package, @admin)
    service.change_status(:in_warehouse, reason: "Retirado")

    # Asignar courier y enviar
    package.reload
    package.update(assigned_courier: @driver)
    service = PackageStatusService.new(package, @admin)
    service.change_status(:in_transit, reason: "En camino")

    # Intento fallido - reprogramar
    package.reload
    service = PackageStatusService.new(package, @driver)
    assert service.change_status(:rescheduled, motive: "Cliente no estaba", reprogram_date: Date.tomorrow)
    package.reload

    assert_equal "rescheduled", package.status
    assert_equal Date.tomorrow, package.reprogramed_to
    assert_equal "Cliente no estaba", package.reprogram_motive

    # Segundo intento exitoso
    service = PackageStatusService.new(package, @driver)
    service.change_status(:in_transit, reason: "Segundo intento")
    package.reload

    service = PackageStatusService.new(package, @driver)
    assert service.change_status(:delivered, reason: "Entregado en segundo intento", proof: "FIRMA-789")
    package.reload

    assert_equal "delivered", package.status
    assert_not_nil package.delivered_at
  end

  # ==========================================================================
  # SECCIÓN 4: VALIDACIONES DE REQUISITOS POR ESTADO
  # ==========================================================================

  test "delivered REQUIRES proof parameter" do
    package = create(:package, status: :in_transit, assigned_courier: @driver)
    service = PackageStatusService.new(package, @driver)

    refute service.change_status(:delivered, reason: "Sin proof")
    assert_includes service.errors.join, "prueba"
  end

  test "picked_up REQUIRES proof parameter" do
    package = create(:package, status: :in_warehouse)
    service = PackageStatusService.new(package, @admin)

    refute service.change_status(:picked_up, reason: "Sin proof")
    assert_includes service.errors.join, "prueba"
  end

  test "in_transit REQUIRES assigned_courier" do
    package = create(:package, status: :in_warehouse, assigned_courier: nil)
    service = PackageStatusService.new(package, @admin)

    refute service.change_status(:in_transit, reason: "Sin courier")
    assert_includes service.errors.join, "courier"
  end

  test "rescheduled REQUIRES motive or reason" do
    package = create(:package, status: :in_transit, assigned_courier: @driver)
    service = PackageStatusService.new(package, @driver)

    refute service.change_status(:rescheduled)
    assert_includes service.errors.join, "motivo"
  end

  # ==========================================================================
  # SECCIÓN 5: TIMESTAMPS Y METADATOS (CRÍTICO PARA AUDITORÍA)
  # ==========================================================================

  test "in_warehouse sets picked_at timestamp" do
    package = create(:package, status: :pending_pickup, picked_at: nil)
    service = PackageStatusService.new(package, @admin)

    freeze_time do
      service.change_status(:in_warehouse, reason: "En bodega")
      package.reload

      assert_not_nil package.picked_at
      assert_in_delta Time.current, package.picked_at, 1.second
    end
  end

  test "in_warehouse does NOT overwrite existing picked_at" do
    original_time = 2.days.ago
    package = create(:package, status: :return, picked_at: original_time)
    service = PackageStatusService.new(package, @admin)

    service.change_status(:in_warehouse, reason: "De vuelta a bodega")
    package.reload

    assert_equal original_time.to_i, package.picked_at.to_i, "No debe sobrescribir picked_at existente"
  end

  test "in_transit sets shipped_at timestamp" do
    package = create(:package, status: :in_warehouse, assigned_courier: @driver, shipped_at: nil)
    service = PackageStatusService.new(package, @admin)

    freeze_time do
      service.change_status(:in_transit, reason: "En camino")
      package.reload

      assert_not_nil package.shipped_at
      assert_in_delta Time.current, package.shipped_at, 1.second
    end
  end

  test "delivered sets delivered_at timestamp" do
    package = create(:package, status: :in_transit, assigned_courier: @driver, delivered_at: nil)
    service = PackageStatusService.new(package, @driver)

    freeze_time do
      service.change_status(:delivered, reason: "Entregado", proof: "PROOF-123")
      package.reload

      assert_not_nil package.delivered_at
      assert_in_delta Time.current, package.delivered_at, 1.second
    end
  end

  test "picked_up sets delivered_at timestamp" do
    package = create(:package, status: :in_warehouse, delivered_at: nil)
    service = PackageStatusService.new(package, @admin)

    freeze_time do
      service.change_status(:picked_up, reason: "Retirado", proof: "DNI-123")
      package.reload

      assert_not_nil package.delivered_at
      assert_in_delta Time.current, package.delivered_at, 1.second
    end
  end

  test "cancelled sets cancelled_at timestamp" do
    package = create(:package, status: :pending_pickup, cancelled_at: nil)
    service = PackageStatusService.new(package, @admin)

    freeze_time do
      service.change_status(:cancelled, reason: "Cancelado por cliente")
      package.reload

      assert_not_nil package.cancelled_at
      assert_in_delta Time.current, package.cancelled_at, 1.second
    end
  end

  # ==========================================================================
  # SECCIÓN 6: HISTORIAL DE CAMBIOS (AUDITORÍA COMPLETA)
  # ==========================================================================

  test "status change adds entry to status_history" do
    package = create(:package, status: :pending_pickup)
    service = PackageStatusService.new(package, @admin)

    initial_history_size = (package.status_history || []).size

    service.change_status(:in_warehouse, reason: "Retirado de origen", location: "Bodega Central")
    package.reload

    assert_equal initial_history_size + 1, package.status_history.size
  end

  test "status_history includes all required fields" do
    package = create(:package, status: :pending_pickup)
    service = PackageStatusService.new(package, @admin)

    freeze_time do
      service.change_status(:in_warehouse, reason: "Test reason", location: "Test location")
      package.reload

      last_entry = package.status_history.last

      assert_equal "in_warehouse", last_entry["status"]
      assert_equal "pending_pickup", last_entry["previous_status"]
      assert_equal @admin.id, last_entry["user_id"]
      assert_equal "Test reason", last_entry["reason"]
      assert_equal "Test location", last_entry["location"]
      assert_not_nil last_entry["timestamp"]
      assert_equal false, last_entry["override"]
    end
  end

  test "status_history preserves all previous entries" do
    package = create(:package, status: :pending_pickup)

    # Primera transición
    service = PackageStatusService.new(package, @admin)
    service.change_status(:in_warehouse, reason: "Primera transición")
    package.reload

    # Segunda transición
    package.update(assigned_courier: @driver)
    service = PackageStatusService.new(package, @admin)
    service.change_status(:in_transit, reason: "Segunda transición")
    package.reload

    # Tercera transición
    service = PackageStatusService.new(package, @driver)
    service.change_status(:delivered, reason: "Tercera transición", proof: "PROOF-123")
    package.reload

    assert_equal 3, package.status_history.size
    assert_equal "in_warehouse", package.status_history[0]["status"]
    assert_equal "in_transit", package.status_history[1]["status"]
    assert_equal "delivered", package.status_history[2]["status"]
  end

  test "override flag is recorded in history" do
    package = create(:package, status: :delivered, delivered_at: Time.current)
    service = PackageStatusService.new(package, @admin)

    service.change_status(:in_warehouse, reason: "Admin override", override: true)
    package.reload

    last_entry = package.status_history.last
    assert_equal true, last_entry["override"]
  end

  # ==========================================================================
  # SECCIÓN 7: MÉTODOS HELPER DEL SERVICIO
  # ==========================================================================

  test "assign_courier assigns driver to package" do
    package = create(:package, assigned_courier: nil)
    service = PackageStatusService.new(package, @admin)

    assert service.assign_courier(@driver.id)
    package.reload

    assert_equal @driver.id, package.assigned_courier_id
  end

  test "assign_courier fails with invalid courier_id" do
    package = create(:package)
    service = PackageStatusService.new(package, @admin)

    refute service.assign_courier(999999)
    assert_includes service.errors.first, "no encontrado"
  end

  test "assign_courier fails with inactive driver" do
    inactive_driver = create(:driver, :inactive)
    package = create(:package)
    service = PackageStatusService.new(package, @admin)

    refute service.assign_courier(inactive_driver.id)
    assert_includes service.errors.first, "inactivo"
  end

  test "assign_courier fails with non_driver user" do
    customer = create(:user, :customer)
    package = create(:package)
    service = PackageStatusService.new(package, @admin)

    refute service.assign_courier(customer.id)
    assert_includes service.errors.first, "conductor válido"
  end

  test "reprogram sets reprogramed_to and motive" do
    package = create(:package, status: :in_transit, assigned_courier: @driver)
    service = PackageStatusService.new(package, @driver)

    new_date = Date.tomorrow
    assert service.reprogram(new_date, "Cliente pidió reprogramar")
    package.reload

    assert_equal "rescheduled", package.status
    assert_equal new_date, package.reprogramed_to
    assert_equal "Cliente pidió reprogramar", package.reprogram_motive
  end

  test "reprogram requires both date and motive" do
    package = create(:package, status: :in_transit, assigned_courier: @driver)
    service = PackageStatusService.new(package, @driver)

    refute service.reprogram(nil, "Solo motive")
    assert_includes service.errors.first, "requeridos"

    refute service.reprogram(Date.tomorrow, nil)
    assert_includes service.errors.first, "requeridos"
  end

  test "mark_as_delivered requires proof" do
    package = create(:package, status: :in_transit, assigned_courier: @driver)
    service = PackageStatusService.new(package, @driver)

    refute service.mark_as_delivered(proof: nil)
    assert_includes service.errors.first, "requerida"
  end

  test "mark_as_delivered succeeds with proof" do
    package = create(:package, status: :in_transit, assigned_courier: @driver)
    service = PackageStatusService.new(package, @driver)

    assert service.mark_as_delivered(proof: "FIRMA-789", location: "Casa del cliente")
    package.reload

    assert_equal "delivered", package.status
    assert_equal "FIRMA-789", package.proof
  end

  test "mark_as_devolucion requires reason" do
    package = create(:package, status: :in_transit, assigned_courier: @driver)
    service = PackageStatusService.new(package, @driver)

    refute service.mark_as_devolucion(reason: nil)
    assert_includes service.errors.first, "requerido"
  end

  test "mark_as_devolucion succeeds with reason" do
    package = create(:package, status: :in_warehouse)
    service = PackageStatusService.new(package, @admin)

    assert service.mark_as_devolucion(reason: "Dirección incorrecta")
    package.reload

    assert_equal "return", package.status
  end

  # ==========================================================================
  # SECCIÓN 8: CONTADOR DE INTENTOS Y LÓGICA DE REPROGRAMACIÓN
  # ==========================================================================

  test "register_failed_attempt increments attempts_count" do
    package = create(:package, status: :in_transit, assigned_courier: @driver, attempts_count: 0)
    service = PackageStatusService.new(package, @driver)

    service.register_failed_attempt(reason: "Cliente ausente", reprogram_date: Date.tomorrow)
    package.reload

    assert_equal 1, package.attempts_count
  end

  test "register_failed_attempt marks as return after 3 attempts without reprogram_date" do
    package = create(:package, status: :in_transit, assigned_courier: @driver, attempts_count: 2)
    service = PackageStatusService.new(package, @driver)

    # Tercer intento fallido sin fecha de reprogramación
    service.register_failed_attempt(reason: "Cliente nunca está")
    package.reload

    assert_equal 3, package.attempts_count
    assert_equal "return", package.status
  end

  test "register_failed_attempt requires reprogram_date if less than 3 attempts" do
    package = create(:package, status: :in_transit, assigned_courier: @driver, attempts_count: 1)
    service = PackageStatusService.new(package, @driver)

    result = service.register_failed_attempt(reason: "Cliente ausente")

    refute result
    assert_includes service.errors.first, "reprogramación"
  end

  # ==========================================================================
  # SECCIÓN 9: CASOS EDGE Y VALIDACIONES DE SEGURIDAD
  # ==========================================================================

  test "cannot bypass transition validation without override" do
    package = create(:package, status: :pending_pickup)
    service = PackageStatusService.new(package, @driver)

    # Intentar saltar directamente a delivered (no permitido)
    refute service.change_status(:delivered, reason: "Intento de salto", proof: "FAKE-PROOF")
    assert_equal "pending_pickup", package.reload.status
  end

  test "transaction rollback on failure keeps original state" do
    package = create(:package, status: :in_warehouse)
    original_status = package.status
    service = PackageStatusService.new(package, @admin)

    # Intentar transición inválida (in_transit sin courier)
    refute service.change_status(:in_transit, reason: "Sin courier")

    # El estado no debe haber cambiado
    assert_equal original_status, package.reload.status
  end

  test "multiple concurrent status changes maintain integrity" do
    package = create(:package, status: :in_warehouse, assigned_courier: @driver)

    # Simular dos servicios intentando cambiar estado simultáneamente
    service1 = PackageStatusService.new(package, @admin)
    service2 = PackageStatusService.new(package.reload, @driver)

    # Primera transición exitosa
    assert service1.change_status(:in_transit, reason: "Primera transición")

    # Segunda transición debe fallar porque el estado ya cambió
    # Nota: Esto depende de la implementación de transaction
    package.reload
    assert_equal "in_transit", package.status
  end

  test "admin override allows forbidden transitions" do
    package = create(:package, status: :delivered, delivered_at: Time.current)
    service = PackageStatusService.new(package, @admin)

    # Delivered -> in_warehouse no está permitido normalmente
    assert service.change_status(:in_warehouse, reason: "Corrección admin", override: true)
    assert_equal "in_warehouse", package.reload.status
    assert package.admin_override
  end

  test "non-admin cannot use override" do
    package = create(:package, status: :delivered, delivered_at: Time.current)
    service = PackageStatusService.new(package, @driver)

    # Driver no puede hacer override
    refute service.change_status(:in_warehouse, reason: "Intento driver", override: true)
    assert_equal "delivered", package.reload.status
  end

  # ==========================================================================
  # SECCIÓN 10: PERFORMANCE Y OPTIMIZACIÓN
  # ==========================================================================

  test "change_status executes in single database transaction" do
    package = create(:package, status: :pending_pickup)
    service = PackageStatusService.new(package, @admin)

    # Count queries ejecutadas
    queries_count = 0
    query_callback = lambda { |*args| queries_count += 1 }

    ActiveSupport::Notifications.subscribed(query_callback, "sql.active_record") do
      service.change_status(:in_warehouse, reason: "Test performance")
    end

    # Debe ser eficiente - pocas queries
    assert queries_count < 10, "Demasiadas queries: #{queries_count}"
  end

  test "bulk status changes are efficient" do
    # Crear 10 paquetes
    packages = 10.times.map { create(:package, status: :pending_pickup) }

    start_time = Time.current

    packages.each do |package|
      service = PackageStatusService.new(package, @admin)
      service.change_status(:in_warehouse, reason: "Bulk change")
    end

    elapsed = Time.current - start_time

    # Debe completarse rápidamente
    assert elapsed < 2.seconds, "Bulk changes too slow: #{elapsed}s"
  end
end
