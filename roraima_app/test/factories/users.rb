FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@roraima.cl" }
    password { "password123" }
    password_confirmation { "password123" }
    sequence(:rut) { |n| format("%d.%03d.%03d-%d", n % 19 + 1, (n * 3) % 1000, (n * 7) % 1000, n % 10) }
    sequence(:phone) { |n| "+569#{sprintf('%08d', 10000000 + n)}" }
    sequence(:company) { |n| "Empresa #{n} S.A." }
    delivery_charge { [3000, 4000, 5000, 6000].sample }
    role { :customer }
    active { true }

    # Trait for admin users
    trait :admin do
      role { :admin }
      sequence(:email) { |n| "admin#{n}@roraima.cl" }
      sequence(:rut) { |n| format("%d.%03d.%03d-k", n % 19 + 1, (n * 2) % 1000, (n * 4) % 1000) }
      active { true }
    end

    # Trait for customer users con información completa
    trait :customer do
      role { :customer }
      sequence(:rut) { |n| format("1%d.%03d.%03d-9", n % 10, (n * 3) % 1000, (n * 7) % 1000) }
      sequence(:phone) { |n| "+569#{sprintf('%08d', 10000000 + n)}" }
      sequence(:company) { |n| "Empresa #{n} S.A." }
      delivery_charge { [3000, 4000, 5000, 6000].sample }
      active { true }
    end

    # Trait for driver users
    trait :driver do
      role { :driver }
      sequence(:email) { |n| "driver#{n}@roraima.cl" }
      sequence(:rut) { |n| format("2%d.%03d.%03d-k", n % 10, (n * 5) % 1000, (n * 9) % 1000) }
      sequence(:phone) { |n| "+569#{sprintf('%08d', 20000000 + n)}" }
      active { true }
    end

    # Trait for inactive users
    trait :inactive do
      active { false }
    end

    # Trait for user with packages
    trait :with_packages do
      after(:create) do |user|
        create_list(:package, 3, user: user)
      end
    end
  end
end
