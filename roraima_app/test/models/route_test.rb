require "test_helper"

class RouteTest < ActiveSupport::TestCase
  # Associations
  test "belongs to driver" do
    driver = create(:driver)
    route = create(:route, driver: driver)

    assert_equal driver, route.driver
  end

  # Validations
  test "valid route with all required fields" do
    route = build(:route)
    assert route.valid?
  end

  test "invalid without driver" do
    route = build(:route, driver: nil)
    assert_not route.valid?
    assert_includes route.errors[:driver], "must exist"
  end

  test "invalid without started_at" do
    route = build(:route, started_at: nil)
    assert_not route.valid?
    assert_includes route.errors[:started_at], "can't be blank"
  end

  test "invalid if ended_at is before started_at" do
    route = build(:route, started_at: Time.current, ended_at: 1.hour.ago)
    assert_not route.valid?
    assert_includes route.errors[:ended_at], "debe ser posterior a la fecha de inicio"
  end

  test "packages_delivered defaults to 0" do
    route = create(:route)
    assert_equal 0, route.packages_delivered
  end

  test "packages_delivered must be non-negative" do
    route = build(:route, packages_delivered: -5)
    assert_not route.valid?
    assert_includes route.errors[:packages_delivered], "must be greater than or equal to 0"
  end

  # Scopes
  test "by_driver scope filters by driver" do
    driver1 = create(:driver)
    driver2 = create(:driver)
    route1 = create(:route, driver: driver1)
    route2 = create(:route, driver: driver2)

    routes = Route.by_driver(driver1.id)

    assert_includes routes, route1
    assert_not_includes routes, route2
  end

  test "recent_first scope orders by started_at descending" do
    driver = create(:driver)
    route1 = create(:route, driver: driver, started_at: 3.days.ago)
    route2 = create(:route, driver: driver, started_at: 1.day.ago)
    route3 = create(:route, driver: driver, started_at: 2.days.ago)

    routes = Route.by_driver(driver.id).recent_first.to_a

    assert_equal [route2, route3, route1], routes
  end

  test "completed_routes scope filters completed only" do
    driver = create(:driver)
    active = create(:route, driver: driver, status: :active)
    completed = create(:route, driver: driver, status: :completed, ended_at: Time.current)

    routes = Route.completed_routes

    assert_includes routes, completed
    assert_not_includes routes, active
  end

  # Auto-rotation logic
  test "rotate_for_driver keeps only last 3 routes" do
    driver = create(:driver)

    # Create 5 routes
    route1 = create(:route, driver: driver, started_at: 5.days.ago, status: :completed, ended_at: 5.days.ago + 2.hours)
    route2 = create(:route, driver: driver, started_at: 4.days.ago, status: :completed, ended_at: 4.days.ago + 2.hours)
    route3 = create(:route, driver: driver, started_at: 3.days.ago, status: :completed, ended_at: 3.days.ago + 2.hours)
    route4 = create(:route, driver: driver, started_at: 2.days.ago, status: :completed, ended_at: 2.days.ago + 2.hours)
    route5 = create(:route, driver: driver, started_at: 1.day.ago, status: :completed, ended_at: 1.day.ago + 2.hours)

    # Rotate
    Route.rotate_for_driver(driver.id)

    # Should keep 3 most recent, delete 2 oldest
    assert_not Route.exists?(route1.id)
    assert_not Route.exists?(route2.id)
    assert Route.exists?(route3.id)
    assert Route.exists?(route4.id)
    assert Route.exists?(route5.id)

    assert_equal 3, driver.routes.count
  end

  test "rotate_for_driver does nothing with 3 or fewer routes" do
    driver = create(:driver)

    route1 = create(:route, driver: driver, started_at: 3.days.ago)
    route2 = create(:route, driver: driver, started_at: 2.days.ago)
    route3 = create(:route, driver: driver, started_at: 1.day.ago)

    Route.rotate_for_driver(driver.id)

    assert_equal 3, driver.routes.count
    assert Route.exists?(route1.id)
    assert Route.exists?(route2.id)
    assert Route.exists?(route3.id)
  end

  test "rotate_for_driver does not affect other drivers" do
    driver1 = create(:driver)
    driver2 = create(:driver)

    # Driver 1: 5 routes
    5.times { |i| create(:route, driver: driver1, started_at: (5-i).days.ago) }

    # Driver 2: 2 routes
    2.times { |i| create(:route, driver: driver2, started_at: (2-i).days.ago) }

    Route.rotate_for_driver(driver1.id)

    assert_equal 3, driver1.routes.count
    assert_equal 2, driver2.routes.count
  end

  # Business methods
  test "duration_in_hours calculates correctly" do
    route = create(:route, started_at: Time.current, ended_at: Time.current + 3.5.hours)

    assert_equal 3.5, route.duration_in_hours
  end

  test "duration_in_hours returns nil if ended_at is nil" do
    route = create(:route, started_at: Time.current, ended_at: nil)

    assert_nil route.duration_in_hours
  end

  test "status_i18n returns Spanish translation" do
    active = build(:route, status: :active)
    completed = build(:route, status: :completed, ended_at: Time.current)

    assert_equal "En Curso", active.status_i18n
    assert_equal "Completada", completed.status_i18n
  end
end
