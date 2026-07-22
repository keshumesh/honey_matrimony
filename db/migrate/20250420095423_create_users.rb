class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :profile_for
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :gender
      t.date :dob
      t.string :time_of_birth
      t.string :rashi
      t.string :nakshtra
      t.string :height
      t.string :marital_status
      t.string :religion
      t.string :mother_tongue
      t.string :caste
      t.string :sub_caste
      t.string :gotra
      t.string :ban
      t.string :manglik
      t.string :complexion
      t.string :heighst_education
      t.string :job
      t.string :organization_name
      t.string :annual_income
      t.string :f_first_name
      t.string :f_middle_name
      t.string :f_last_name
      t.string :m_first_name
      t.string :m_middle_name
      t.string :m_last_name
      t.integer :sisters
      t.integer :brothers
      t.string :mobile_no
      t.string :email
      t.string :address

      t.timestamps
    end
  end
end
