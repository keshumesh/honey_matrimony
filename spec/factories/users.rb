FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    first_name { 'John' }
    last_name { 'Doe' }
    mobile_no { '9876543210' }
    gender { 'Male' }
    dob { 30.years.ago }
    height { '5.10' }
    religion { 'Hindu' }
    caste { 'Brahmin' }
    complexion { 'Fair' }
    marital_status { 'Single' }
    mother_tongue { 'Hindi' }
    role { 'user' }

    trait :admin do
      role { 'admin' }
      # Admin only requires personal details, other fields are optional
      # So we still provide them for factory consistency, but they won't be required
      dob { nil }
      height { nil }
      religion { nil }
      caste { nil }
      complexion { nil }
      marital_status { nil }
      mother_tongue { nil }
      last_name { nil }
    end

    trait :manager do
      role { 'manager' }
    end

    trait :with_complete_profile do
      profile_for { 'Self' }
      rashi { 'Aries' }
      nakshtra { 'Ashwini' }
      manglik { false }
      heighst_education { 'Bachelor' }
      job { 'Software Engineer' }
      organization_name { 'Tech Company' }
      annual_income { '1000000' }
      f_first_name { 'Father' }
      f_last_name { 'Name' }
      m_first_name { 'Mother' }
      m_last_name { 'Name' }
      sisters { 1 }
      brothers { 2 }
      address { '123 Main St, City' }
    end
  end
end
