FactoryBot.define do
  factory :driver, class: 'Driver', parent: :user do
    type { 'Driver' }
    role { :driver }
    sequence(:name) { |n| "Conductor #{n}" }
    sequence(:email) { |n| "driver#{n}@roraima.cl" }
    sequence(:rut) { |n| format("2%d.%03d.%03d-k", n % 10, (n * 5) % 1000, (n * 9) % 1000) }
    sequence(:phone) { |n| "+569#{sprintf('%08d', 20000000 + n)}" }
    sequence(:vehicle_plate) { |n| "ABCD#{sprintf('%02d', n % 100)}" }
    vehicle_model { "Toyota Hilux 2020" }
    vehicle_capacity { 500 }
    active { true }

    # Trait for driver with assigned zone
    trait :with_zone do
      association :assigned_zone, factory: :zone
    end

    # Trait for inactive driver
    trait :inactive do
      active { false }
    end

    # Trait for driver with packages assigned
    trait :with_packages do
      after(:create) do |driver|
        create_list(:package, 3, assigned_courier: driver, status: :in_transit)
      end
    end
  end
end
