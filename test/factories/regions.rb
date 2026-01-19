FactoryBot.define do
  factory :region do
    sequence(:name) { |n| "Región #{n}" }

    # Predefined regions for Chilean geography
    trait :metropolitana do
      name { "Región Metropolitana" }
    end

    trait :valparaiso do
      name { "Región de Valparaíso" }
    end

    trait :biobio do
      name { "Región del Biobío" }
    end

    # Trait for region with communes
    trait :with_communes do
      after(:create) do |region|
        create_list(:commune, 3, region: region)
      end
    end
  end
end
