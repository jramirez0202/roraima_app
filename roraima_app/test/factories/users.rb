FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@roraima.cl" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :customer }  # Usar enum role en lugar de admin boolean

    # Trait for admin users
    trait :admin do
      role { :admin }  # Usar enum role
      sequence(:email) { |n| "admin#{n}@roraima.cl" }
    end

    # Trait for customer users (explícito)
    trait :customer do
      role { :customer }
    end

    # Trait for user with packages
    trait :with_packages do
      after(:create) do |user|
        create_list(:package, 3, user: user)
      end
    end
  end
end
