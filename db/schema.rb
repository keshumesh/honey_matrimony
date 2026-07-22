# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_07_04_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "user_interactions", force: :cascade do |t|
    t.bigint "from_user_id", null: false
    t.bigint "to_user_id", null: false
    t.string "interaction_type", default: "interested", null: false
    t.text "notes"
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_user_id", "to_user_id"], name: "index_user_interactions_on_from_user_id_and_to_user_id", unique: true
    t.index ["from_user_id"], name: "index_user_interactions_on_from_user_id"
    t.index ["to_user_id"], name: "index_user_interactions_on_to_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "profile_for"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "gender"
    t.date "dob"
    t.string "time_of_birth"
    t.string "rashi"
    t.string "nakshtra"
    t.string "height"
    t.string "marital_status"
    t.string "religion"
    t.string "mother_tongue"
    t.string "caste"
    t.string "sub_caste"
    t.string "gotra"
    t.string "ban"
    t.string "manglik"
    t.string "complexion"
    t.string "heighst_education"
    t.string "job"
    t.string "organization_name"
    t.string "annual_income"
    t.string "f_first_name"
    t.string "f_middle_name"
    t.string "f_last_name"
    t.string "m_first_name"
    t.string "m_middle_name"
    t.string "m_last_name"
    t.integer "sisters"
    t.integer "brothers"
    t.string "mobile_no"
    t.string "email"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "role", default: "user"
    t.string "avatar"
    t.string "additional_photos"
    t.string "blood_group"
    t.string "extra_phone_number"
    t.string "maternal_surname"
    t.text "gallery_photos", default: "[]", comment: "JSON array storing up to 5 photo filenames"
    t.text "hobbies"
    t.string "highest_educational_details"
    t.string "father_occupation"
    t.text "family_details"
    t.text "any_requirement"
    t.string "food_type", default: "Vegetarian"
    t.string "provider"
    t.string "uid"
    t.string "google_access_token"
    t.string "facebook_access_token"
    t.string "login_type", default: "email"
    t.text "bio", default: ""
    t.integer "profile_views_count", default: 0
    t.string "voice_prompt_url"
    t.integer "voice_prompt_duration", default: 0
    t.boolean "willing_to_relocate", default: true
    t.string "smoking_frequency", default: "Never"
    t.string "alcohol_frequency", default: "Never"
    t.index ["mobile_no"], name: "index_users_on_mobile_no"
    t.index ["profile_views_count"], name: "index_users_on_profile_views_count"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "user_interactions", "users", column: "from_user_id"
  add_foreign_key "user_interactions", "users", column: "to_user_id"
end
