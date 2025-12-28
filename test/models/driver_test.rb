require "test_helper"

class DriverTest < ActiveSupport::TestCase
  # ====================
  # Factory Tests
  # ====================
  test "valid driver factory should be valid" do
    driver = build(:driver)
    assert driver.valid?, "Driver factory should create valid driver"
  end

  test "driver with zone factory should be valid" do
    driver = build(:driver, :with_zone)
    assert driver.valid?, "Driver with zone factory should be valid"
    assert_not_nil driver.assigned_zone
  end

  # ====================
  # STI (Single Table Inheritance)
  # ====================
  test "driver should inherit from User" do
    driver = create(:driver)
    assert_instance_of Driver, driver
    assert_kind_of User, driver
    assert_equal "Driver", driver.type
  end

  test "driver should have role driver" do
    driver = create(:driver)
    assert driver.driver?
    assert_not driver.admin?
    assert_not driver.customer?
  end

  # ====================
  # Vehicle Validations (Ahora opcionales)
  # ====================
  test "vehicle_plate is optional" do
    driver = build(:driver, vehicle_plate: nil)
    assert driver.valid?, "Driver should be valid without vehicle_plate"
  end

  test "vehicle_model is optional" do
    driver = build(:driver, vehicle_model: nil)
    assert driver.valid?, "Driver should be valid without vehicle_model"
  end

  test "vehicle_capacity is optional" do
    driver = build(:driver, vehicle_capacity: nil)
    assert driver.valid?, "Driver should be valid without vehicle_capacity"
  end

  test "vehicle_capacity should be greater than 0" do
    driver = build(:driver, vehicle_capacity: 0)
    assert_not driver.valid?
    assert_includes driver.errors[:vehicle_capacity], "must be greater than 0"

    driver.vehicle_capacity = -100
    assert_not driver.valid?
  end

  test "vehicle_capacity accepts positive values" do
    driver = build(:driver, vehicle_capacity: 500)
    assert driver.valid?

    driver.vehicle_capacity = 1500
    assert driver.valid?
  end

  # ====================
  # Vehicle Plate Format Validation
  # ====================
  test "should accept valid Chilean plate format ABCD12" do
    valid_plates = ["ABCD12", "XYZA99", "BBCC01"]

    valid_plates.each do |plate|
      driver = build(:driver, vehicle_plate: plate)
      assert driver.valid?, "#{plate} should be valid"
    end
  end

  test "should accept valid Chilean plate format AB1234" do
    valid_plates = ["AB1234", "XY9999", "BC0001"]

    valid_plates.each do |plate|
      driver = build(:driver, vehicle_plate: plate)
      assert driver.valid?, "#{plate} should be valid"
    end
  end

  test "should reject invalid plate formats" do
    invalid_plates = [
      "ABC123",    # Solo 3 letras
      "ABCDE1",    # 5 letras
      "AB123",     # Solo 3 números
      "123456",    # Solo números
      "ABCDEF",    # Solo letras
      "ab1234",    # Minúsculas
      "AB-1234",   # Con guión
      "AB 1234"    # Con espacio
    ]

    invalid_plates.each do |plate|
      driver = build(:driver, vehicle_plate: plate)
      assert_not driver.valid?, "#{plate} should be invalid"
      assert_includes driver.errors[:vehicle_plate], "debe ser formato chileno (ABCD12 o AB1234)"
    end
  end

  test "vehicle_plate should be unique" do
    driver1 = create(:driver, vehicle_plate: "XXXX12")
    driver2 = build(:driver, vehicle_plate: "XXXX12")

    assert_not driver2.valid?
    assert_includes driver2.errors[:vehicle_plate], "has already been taken"
  end

  # ====================
  # Zone Association
  # ====================
  test "should belong to assigned_zone optionally" do
    driver = create(:driver, assigned_zone: nil)
    assert driver.valid?
    assert_nil driver.assigned_zone
  end

  test "should accept zone assignment" do
    zone = create(:zone)
    driver = create(:driver, assigned_zone: zone)

    assert driver.valid?
    assert_equal zone.id, driver.assigned_zone_id
    assert_instance_of Zone, driver.assigned_zone
  end

  # ====================
  # Packages Association
  # ====================
  test "should have assigned_packages association" do
    driver = create(:driver)
    assert_respond_to driver, :assigned_packages
  end

  test "assigned_packages should return packages assigned to driver" do
    driver = create(:driver)
    other_driver = create(:driver)

    package1 = create(:package, assigned_courier: driver, status: :in_transit)
    package2 = create(:package, assigned_courier: driver, status: :in_warehouse)
    package3 = create(:package, assigned_courier: other_driver, status: :in_transit)

    assert_equal 2, driver.assigned_packages.count
    assert_includes driver.assigned_packages, package1
    assert_includes driver.assigned_packages, package2
    assert_not_includes driver.assigned_packages, package3
  end

  test "destroying driver should nullify package assignments" do
    driver = create(:driver)
    package = create(:package, assigned_courier: driver, status: :in_transit)

    driver_id = driver.id
    driver.destroy

    package.reload
    assert_nil package.assigned_courier_id
    assert_not_equal driver_id, package.assigned_courier_id
  end

  # ====================
  # Instance Methods
  # ====================
  test "visible_packages returns assigned_packages" do
    driver = create(:driver)
    package = create(:package, assigned_courier: driver, status: :in_transit)

    assert_equal driver.assigned_packages, driver.visible_packages
    assert_includes driver.visible_packages, package
  end

  test "today_deliveries returns packages delivered today" do
    driver = create(:driver)

    freeze_time do
      today_package = create(:package, assigned_courier: driver, status: :delivered, delivered_at: Time.current)
      yesterday_package = create(:package, assigned_courier: driver, status: :delivered, delivered_at: 1.day.ago)

      deliveries = driver.today_deliveries

      assert_includes deliveries, today_package
      assert_not_includes deliveries, yesterday_package
      assert_equal 1, deliveries.count
    end
  end

  test "pending_deliveries returns packages ready for delivery (pending_pickup, in_warehouse, in_transit, rescheduled)" do
    driver = create(:driver)

    pending_pickup = create(:package, assigned_courier: driver, status: :pending_pickup)
    in_warehouse = create(:package, assigned_courier: driver, status: :in_warehouse)
    in_transit = create(:package, assigned_courier: driver, status: :in_transit)
    rescheduled = create(:package, assigned_courier: driver, status: :rescheduled)
    delivered = create(:package, assigned_courier: driver, status: :delivered, delivered_at: 1.day.ago)
    cancelled = create(:package, assigned_courier: driver, status: :cancelled)

    pending = driver.pending_deliveries

    # Debe incluir todos los estados "en proceso"
    assert_includes pending, pending_pickup
    assert_includes pending, in_warehouse
    assert_includes pending, in_transit
    assert_includes pending, rescheduled

    # NO debe incluir estados terminales
    assert_not_includes pending, delivered
    assert_not_includes pending, cancelled

    assert_equal 4, pending.count
  end

  # ====================
  # Active/Inactive Status
  # ====================
  test "driver can be inactive" do
    driver = create(:driver, :inactive)
    assert_not driver.active?
  end

  test "inactive driver cannot be assigned to packages" do
    driver = create(:driver, :inactive)
    package = create(:package)

    service = PackageStatusService.new(package, User.admin.first || create(:user, :admin))
    result = service.assign_courier(driver.id)

    assert_not result
    assert_includes service.errors.first, "inactivo"
  end

  # ====================
  # Scopes from User Model
  # ====================
  test "Driver responds to active scope" do
    active_driver = create(:driver, active: true)
    inactive_driver = create(:driver, active: false)

    assert_includes Driver.active, active_driver
    assert_not_includes Driver.active, inactive_driver
  end

  test "Driver responds to inactive scope" do
    active_driver = create(:driver, active: true)
    inactive_driver = create(:driver, active: false)

    assert_includes Driver.inactive, inactive_driver
    assert_not_includes Driver.inactive, active_driver
  end

  # ====================
  # Edge Cases
  # ====================
  test "driver cannot create packages" do
    driver = create(:driver)
    package = build(:package, user: driver)

    assert_not package.valid?
    assert_includes package.errors[:user_id], "no puede ser un Driver. Debe ser un usuario Customer."
  end

  test "driver email should be unique across all users" do
    create(:user, :customer, email: "test@example.com")
    driver = build(:driver, email: "test@example.com")

    assert_not driver.valid?
    assert_includes driver.errors[:email], "has already been taken"
  end

  test "driver should have valid user attributes" do
    driver = create(:driver)

    assert_not_nil driver.email
    assert_not_nil driver.rut
    assert_not_nil driver.encrypted_password
    assert driver.respond_to?(:admin?)
    assert driver.respond_to?(:driver?)
    assert driver.respond_to?(:customer?)
  end

  # Route Management Tests
  test "route_status enum works correctly" do
    driver = create(:driver)
    assert driver.not_started?

    driver.update(route_status: :ready)
    assert driver.ready?

    driver.update(route_status: :on_route)
    assert driver.on_route?

    driver.update(route_status: :completed)
    assert driver.completed?
  end

  test "can_start_route? returns true with valid conditions" do
    driver = create(:driver, ready_for_route: true)
    create(:package, assigned_courier: driver, status: :in_transit)

    assert driver.can_start_route?
  end

  test "can_start_route? returns false without authorization" do
    # Habilitar el requisito de autorización para este test
    Setting.instance.update!(require_driver_authorization: true)

    driver = create(:driver, ready_for_route: false)
    create(:package, assigned_courier: driver, status: :in_transit)

    assert_not driver.can_start_route?
  ensure
    # Restaurar configuración original
    Setting.instance.update!(require_driver_authorization: false)
  end

  test "can_start_route? returns false without packages" do
    driver = create(:driver, ready_for_route: true)

    assert_not driver.can_start_route?
  end

  test "can_start_route? returns false when already on_route" do
    driver = create(:driver, ready_for_route: true, route_status: :on_route)
    create(:package, assigned_courier: driver, status: :in_transit)

    assert_not driver.can_start_route?
  end

  test "route_progress calculates correctly" do
    driver = create(:driver, route_status: :on_route)
    create(:package, assigned_courier: driver, status: :in_transit)
    create(:package, assigned_courier: driver, status: :delivered, delivered_at: Time.current)
    create(:package, assigned_courier: driver, status: :delivered, delivered_at: Time.current)

    progress = driver.route_progress
    assert_equal 2, progress[:delivered]
    assert_equal 3, progress[:total]
  end

  test "route_progress returns zeros when not on route" do
    driver = create(:driver, route_status: :not_started)
    create(:package, assigned_courier: driver, status: :delivered, delivered_at: Time.current)

    progress = driver.route_progress
    assert_equal 0, progress[:delivered]
    assert_equal 0, progress[:total]
  end

  test "route_completion_percentage calculates correctly" do
    driver = create(:driver, route_status: :on_route)
    create(:package, assigned_courier: driver, status: :in_transit)
    create(:package, assigned_courier: driver, status: :delivered, delivered_at: Time.current)

    percentage = driver.route_completion_percentage
    assert_equal 50.0, percentage
  end

  test "route_completion_percentage returns 0 with no packages" do
    driver = create(:driver, route_status: :on_route)

    percentage = driver.route_completion_percentage
    assert_equal 0, percentage
  end

  # ====================
  # Route History Methods
  # ====================
  test "last_routes returns up to 3 most recent routes" do
    driver = create(:driver)

    route1 = create(:route, driver: driver, started_at: 5.days.ago)
    route2 = create(:route, driver: driver, started_at: 3.days.ago)
    route3 = create(:route, driver: driver, started_at: 2.days.ago)
    route4 = create(:route, driver: driver, started_at: 1.day.ago)

    routes = driver.last_routes

    assert_equal 3, routes.size
    assert_equal [route4, route3, route2], routes.to_a
  end

  test "last_routes respects custom limit" do
    driver = create(:driver)

    5.times { |i| create(:route, driver: driver, started_at: (5-i).days.ago) }

    routes = driver.last_routes(limit: 2)

    assert_equal 2, routes.size
  end

  test "current_route returns active route" do
    driver = create(:driver)

    completed = create(:route, driver: driver, status: :completed, started_at: 2.days.ago, ended_at: 2.days.ago + 2.hours)
    active = create(:route, driver: driver, status: :active, started_at: Time.current)

    assert_equal active, driver.current_route
  end

  test "current_route returns nil if no active route" do
    driver = create(:driver)

    create(:route, driver: driver, status: :completed, started_at: 1.day.ago, ended_at: 1.day.ago + 2.hours)

    assert_nil driver.current_route
  end

  test "total_routes_completed counts only completed routes" do
    driver = create(:driver)

    create(:route, driver: driver, status: :completed, started_at: 3.days.ago, ended_at: 3.days.ago + 2.hours)
    create(:route, driver: driver, status: :completed, started_at: 2.days.ago, ended_at: 2.days.ago + 2.hours)
    create(:route, driver: driver, status: :active, started_at: 1.day.ago)

    assert_equal 2, driver.total_routes_completed
  end

  test "destroying driver deletes associated routes" do
    driver = create(:driver)
    route = create(:route, driver: driver)

    assert_difference 'Route.count', -1 do
      driver.destroy
    end

    assert_not Route.exists?(route.id)
  end
end
