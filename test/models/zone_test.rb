require "test_helper"

class ZoneTest < ActiveSupport::TestCase
  # ====================
  # Factory Tests
  # ====================
  test "valid zone factory should be valid" do
    zone = build(:zone)
    assert zone.valid?, "Zone factory should create valid zone"
  end

  test "zone with communes factory should be valid" do
    zone = build(:zone, :with_communes)
    assert zone.valid?, "Zone with communes factory should be valid"
  end

  # ====================
  # Validations
  # ====================
  test "should require name" do
    zone = build(:zone, name: nil)
    assert_not zone.valid?
    assert_includes zone.errors[:name], "can't be blank"
  end

  test "name should be unique" do
    zone1 = create(:zone, name: "Zona Norte")
    zone2 = build(:zone, name: "Zona Norte")

    assert_not zone2.valid?
    assert_includes zone2.errors[:name], "has already been taken"
  end

  # ====================
  # Associations
  # ====================
  test "should belong to region" do
    zone = create(:zone)
    assert_respond_to zone, :region
    assert_instance_of Region, zone.region
  end

  test "should have many drivers" do
    zone = create(:zone)
    assert_respond_to zone, :drivers
  end

  test "drivers association should return drivers assigned to zone" do
    zone = create(:zone)
    driver1 = create(:driver, assigned_zone: zone)
    driver2 = create(:driver, assigned_zone: zone)
    driver3 = create(:driver, assigned_zone: nil)

    assert_equal 2, zone.drivers.count
    assert_includes zone.drivers, driver1
    assert_includes zone.drivers, driver2
    assert_not_includes zone.drivers, driver3
  end

  # ====================
  # Communes Storage (JSONB)
  # ====================
  test "communes should default to empty array" do
    zone = Zone.new(name: "Test", region: create(:region))
    assert_equal [], zone.communes
  end

  test "communes should accept array of commune IDs" do
    region = create(:region)
    communes = create_list(:commune, 3, region: region)
    commune_ids = communes.map(&:id)

    zone = create(:zone, region: region, communes: commune_ids)

    assert_equal commune_ids.sort, zone.communes.sort
    assert_instance_of Array, zone.communes
  end

  # ====================
  # Instance Methods
  # ====================
  test "commune_names returns names of assigned communes" do
    region = create(:region)
    commune1 = create(:commune, region: region, name: "Providencia")
    commune2 = create(:commune, region: region, name: "Las Condes")

    zone = create(:zone, region: region, communes: [commune1.id, commune2.id])

    names = zone.commune_names
    assert_includes names, "Providencia"
    assert_includes names, "Las Condes"
    assert_equal 2, names.count
  end

  # ====================
  # Active/Inactive Status
  # ====================
  test "zone should default to active" do
    zone = Zone.new(name: "Test", region: create(:region))
    assert zone.active
  end

  test "active scope returns only active zones" do
    active_zone = create(:zone, active: true)
    inactive_zone = create(:zone, active: false)

    active_zones = Zone.active

    assert_includes active_zones, active_zone
    assert_not_includes active_zones, inactive_zone
  end
end
