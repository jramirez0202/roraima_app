require "test_helper"

class RouteManagementServiceTest < ActiveSupport::TestCase
  setup do
    # Ensure Setting singleton exists to avoid race conditions in parallel tests
    Setting.instance
  end

  # start_route tests
  test "start_route succeeds with valid conditions" do
    driver = create(:driver, ready_for_route: true)
    create(:package, assigned_courier: driver, status: :in_transit)

    service = RouteManagementService.new(driver)

    freeze_time do
      assert service.start_route
      driver.reload
      assert driver.on_route?
      assert_equal Time.current.beginning_of_hour, driver.route_started_at
    end
  end

  test "start_route fails without ready_for_route" do
    # Habilitar validación de autorización de drivers
    Setting.instance.update!(require_driver_authorization: true)

    driver = create(:driver, ready_for_route: false)
    create(:package, assigned_courier: driver, status: :in_transit)

    service = RouteManagementService.new(driver)

    assert_not service.start_route
    assert_includes service.errors.first, "no ha sido marcado como listo"
    driver.reload
    assert driver.not_started?
  ensure
    # Restaurar configuración
    Setting.instance.update!(require_driver_authorization: false)
  end

  test "start_route fails without packages" do
    driver = create(:driver, ready_for_route: true)

    service = RouteManagementService.new(driver)

    assert_not service.start_route
    assert_includes service.errors.first, "No hay paquetes pendientes"
  end

  test "start_route fails when already on_route" do
    driver = create(:driver, ready_for_route: true, route_status: :on_route)
    create(:package, assigned_courier: driver, status: :in_transit)

    service = RouteManagementService.new(driver)

    assert_not service.start_route
    assert_includes service.errors.first, "ruta ya está en progreso"
  end

  test "start_route fails when driver inactive" do
    driver = create(:driver, ready_for_route: true, active: false)
    create(:package, assigned_courier: driver, status: :in_transit)

    service = RouteManagementService.new(driver)

    assert_not service.start_route
    assert_includes service.errors.first, "Conductor inactivo"
  end

  # complete_route tests
  test "complete_route succeeds when on_route" do
    driver = create(:driver, route_status: :on_route, route_started_at: 2.hours.ago)

    service = RouteManagementService.new(driver)

    freeze_time do
      assert service.complete_route
      driver.reload
      assert driver.completed?
      assert_equal Time.current, driver.route_ended_at
    end
  end

  test "complete_route fails when not on_route" do
    driver = create(:driver, route_status: :not_started)

    service = RouteManagementService.new(driver)

    assert_not service.complete_route
    assert_includes service.errors.first, "no tiene una ruta activa"
  end

  # auto_complete_if_finished tests
  test "auto_complete_if_finished completes when all delivered" do
    driver = create(:driver, route_status: :on_route, route_started_at: 2.hours.ago)
    create(:package, assigned_courier: driver, status: :delivered, delivered_at: Time.current)
    create(:package, assigned_courier: driver, status: :delivered, delivered_at: Time.current)

    service = RouteManagementService.new(driver)

    assert service.auto_complete_if_finished
    driver.reload
    assert driver.completed?
    assert_not_nil driver.route_ended_at
  end

  test "auto_complete_if_finished does not complete with pending packages" do
    driver = create(:driver, route_status: :on_route, route_started_at: 2.hours.ago)
    create(:package, assigned_courier: driver, status: :in_transit)
    create(:package, assigned_courier: driver, status: :delivered, delivered_at: Time.current)

    service = RouteManagementService.new(driver)

    assert_not service.auto_complete_if_finished
    driver.reload
    assert driver.on_route?
  end

  test "auto_complete_if_finished does not complete when not on_route" do
    driver = create(:driver, route_status: :not_started)
    create(:package, assigned_courier: driver, status: :delivered, delivered_at: Time.current)

    service = RouteManagementService.new(driver)

    assert_not service.auto_complete_if_finished
  end

  test "auto_complete_if_finished does not complete with no packages" do
    driver = create(:driver, route_status: :on_route, route_started_at: 2.hours.ago)

    service = RouteManagementService.new(driver)

    assert_not service.auto_complete_if_finished
  end

  # Route model integration tests
  test "start_route creates Route record" do
    driver = create(:driver, ready_for_route: true)
    create(:package, assigned_courier: driver, status: :in_transit)

    service = RouteManagementService.new(driver)

    assert_difference 'Route.count', 1 do
      service.start_route
    end

    route = driver.routes.last
    assert route.active?
    assert_equal 0, route.packages_delivered
    assert_not_nil route.started_at
    assert_nil route.ended_at
  end

  test "start_route calls auto-rotation" do
    driver = create(:driver, ready_for_route: true)
    create(:package, assigned_courier: driver, status: :in_transit)

    # Create 3 old routes
    3.times { |i| create(:route, driver: driver, started_at: (3-i).days.ago, status: :completed, ended_at: (3-i).days.ago + 2.hours) }

    service = RouteManagementService.new(driver)

    # Start new route (should trigger rotation)
    service.start_route

    # Should have exactly 3 routes (deleted oldest, kept 2, added new)
    assert_equal 3, driver.routes.count
  end

  test "complete_route updates Route record with packages count" do
    driver = create(:driver, route_status: :on_route, route_started_at: 2.hours.ago)
    route = create(:route, driver: driver, status: :active, started_at: 2.hours.ago)

    # Create packages delivered during this route
    create(:package, assigned_courier: driver, status: :delivered, delivered_at: 1.hour.ago)
    create(:package, assigned_courier: driver, status: :delivered, delivered_at: 30.minutes.ago)

    # Create package delivered BEFORE route started (should not count)
    create(:package, assigned_courier: driver, status: :delivered, delivered_at: 3.hours.ago)

    service = RouteManagementService.new(driver)

    freeze_time do
      service.complete_route

      route.reload
      assert route.completed?
      assert_equal 2, route.packages_delivered
      assert_equal Time.current, route.ended_at
    end
  end

  test "complete_route handles no active route gracefully" do
    driver = create(:driver, route_status: :on_route, route_started_at: 2.hours.ago)
    # No Route record exists (edge case)

    service = RouteManagementService.new(driver)

    # Should complete without error, just log warning
    assert service.complete_route
    driver.reload
    assert driver.completed?
  end

  test "packages_delivered counts both delivered and picked_up" do
    driver = create(:driver, route_status: :on_route, route_started_at: 2.hours.ago)
    route = create(:route, driver: driver, status: :active, started_at: 2.hours.ago)

    create(:package, assigned_courier: driver, status: :delivered, delivered_at: 1.hour.ago)
    create(:package, assigned_courier: driver, status: :picked_up, delivered_at: 30.minutes.ago)

    service = RouteManagementService.new(driver)
    service.complete_route

    route.reload
    assert_equal 2, route.packages_delivered
  end
end
