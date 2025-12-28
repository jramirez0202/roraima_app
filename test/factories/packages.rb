FactoryBot.define do
  factory :package do
    sequence(:customer_name) { |n| "Cliente #{n}" }
    sender_email { "remitente@example.com" }
    company_name { "Empresa XYZ" }
    address { "Av. Principal 123, Depto 45" }
    description { "Paquete de prueba" }
    sequence(:phone) { |n| "+569#{sprintf('%08d', 10000000 + n)}" }
    exchange { false }
    # loading_date will be set automatically by model callback

    # Required associations
    association :region
    association :commune
    # user must be customer (not admin, not driver)
    association :user, factory: [:user, :customer]

    # Trait for minimal valid package (only required fields)
    trait :minimal do
      customer_name { nil }
      sender_email { nil }
      company_name { nil }
      address { nil }
      description { nil }
      # phone is now required, so keep default valid phone
      # user is also required (belongs_to without optional: true)
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
      sender_email { "sender@roraima.com" }
      company_name { "Roraima Logistics S.A." }
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
