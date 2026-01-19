FactoryBot.define do
  factory :route do
    association :driver
    started_at { 2.hours.ago.beginning_of_hour }
    ended_at { nil }
    status { :active }
    packages_delivered { 0 }

    # Trait for completed route
    trait :completed do
      status { :completed }
      ended_at { 1.hour.ago }
      packages_delivered { rand(1..10) }
    end

    # Trait for route with many packages
    trait :with_packages do
      packages_delivered { rand(10..30) }
    end

    # Trait for old route
    trait :old do
      started_at { 7.days.ago.beginning_of_hour }
      ended_at { 7.days.ago + 3.hours }
      status { :completed }
    end
  end
end
