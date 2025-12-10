FactoryBot.define do
  factory :zone do
    sequence(:name) { |n| "Zona #{n}" }
    association :region
    communes { [] }
    active { true }

    # Trait for zone with communes from Región Metropolitana
    trait :with_communes do
      after(:build) do |zone|
        if zone.region.present?
          # Tomar las primeras 3 comunas de la región
          commune_ids = zone.region.communes.limit(3).pluck(:id)
          zone.communes = commune_ids
        end
      end
    end

    # Trait for inactive zone
    trait :inactive do
      active { false }
    end

    # Trait for zone with specific region (Metropolitana)
    trait :metropolitana do
      association :region, factory: :region, name: 'Región Metropolitana'
    end
  end
end
