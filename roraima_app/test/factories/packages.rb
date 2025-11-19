FactoryBot.define do
  factory :package do
    sequence(:customer_name) { |n| "Cliente #{n}" }
    company { "Empresa XYZ" }
    address { "Av. Principal 123, Depto 45" }
    description { "Paquete de prueba" }
    phone { "+56912345678" }
    exchange { false }
    pickup_date { Date.tomorrow }

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
      phone { nil }
      user { nil }
    end

    # Trait for package scheduled for today
    trait :today do
      pickup_date { Date.today }
    end

    # Trait for exchange package
    trait :exchange do
      exchange { true }
    end

    # Trait for package without user
    trait :no_user do
      user { nil }
    end

    # Trait for past pickup date (invalid)
    trait :past_date do
      pickup_date { Date.yesterday }
    end

    # Trait for package with all optional fields
    trait :complete do
      customer_name { "Juan Pérez González" }
      company { "Roraima Logistics S.A." }
      address { "Av. Libertador Bernardo O'Higgins 1234, Oficina 567" }
      description { "Paquete urgente con documentos importantes y muestras" }
      phone { "+56 9 8765 4321" }
    end
  end
end
