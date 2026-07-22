FactoryBot.define do
  factory :user_interaction do
    from_user { nil }
    to_user { nil }
    interaction_type { "MyString" }
    notes { "MyText" }
    status { "MyString" }
  end
end
