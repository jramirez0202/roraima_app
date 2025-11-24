FactoryBot.define do
  factory :package do
    sequence(:customer_name) { |n| "Cliente #{n}" }
    company { "Empresa XYZ" }
    address { "Av. Principal 123, Depto 45" }
    description { "Paquete de prueba" }
    sequence(:phone) { |n| "+569#{sprintf('%08d', 10000000 + n)}" }
    exchange { false }
    loading_date { Date.tomorrow }

    # Required associations
    association :region
    association :commune
    # user is optional
    association :user

    # Trait for minimal valid package (only required fields)
    trait :minimal do
      customer_name { nil }
      company { nil }
      address { nil }
      description { nil }
      # phone is now required, so keep default valid phone
      user { nil }
    end

    # Trait for package scheduled for today
    trait :today do
      loading_date { Date.today }
    end

    # Trait for exchange package
    trait :exchange do
      exchange { true }
    end

    # Trait for package without user
    trait :no_user do
      user { nil }
    end

    # Trait for past loading date (invalid)
    trait :past_date do
      loading_date { 1.week.ago.to_date }
    end

    # Trait for package with all optional fields
    trait :complete do
      customer_name { "Juan Pérez González" }
      company { "Roraima Logistics S.A." }
      address { "Av. Libertador Bernardo O'Higgins 1234, Oficina 567" }
      description { "Paquete urgente con documentos importantes y muestras" }
      phone { "+56987654321" }
    end

    # Traits for invalid phone formats (for testing)
    trait :invalid_phone_with_spaces do
      phone { "+56 9 1234 5678" }
    end

    trait :invalid_phone_too_short do
      phone { "+5691234567" }
    end

    trait :invalid_phone_too_long do
      phone { "+569123456789" }
    end

    trait :invalid_phone_missing_prefix do
      phone { "912345678" }
    end

    trait :invalid_phone_wrong_prefix do
      phone { "+56812345678" }
    end
  end
end
