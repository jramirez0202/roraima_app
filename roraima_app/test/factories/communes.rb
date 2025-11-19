FactoryBot.define do
  factory :commune do
    sequence(:name) { |n| "Comuna #{n}" }
    association :region

    # Predefined communes
    trait :santiago do
      name { "Santiago" }
    end

    trait :providencia do
      name { "Providencia" }
    end

    trait :vina_del_mar do
      name { "Viña del Mar" }
    end

    trait :las_condes do
      name { "Las Condes" }
    end
  end
end
