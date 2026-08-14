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

ActiveRecord::Schema[7.1].define(version: 2026_08_14_050749) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "care_record_id", null: false
    t.string "storage_key", null: false
    t.string "file_type", null: false
    t.datetime "created_at", null: false
    t.string "original_filename", default: "", null: false
    t.index ["care_record_id"], name: "index_attachments_on_care_record_id"
  end

  create_table "care_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "pet_id", null: false
    t.integer "record_type", null: false
    t.datetime "recorded_at", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pet_id"], name: "index_care_records_on_pet_id"
  end

  create_table "cares", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "care_record_id", null: false
    t.integer "care_type", null: false
    t.datetime "created_at", null: false
    t.index ["care_record_id"], name: "index_cares_on_care_record_id"
  end

  create_table "hospital_names", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_hospital_names_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_hospital_names_on_user_id"
  end

  create_table "hospital_visits", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "care_record_id", null: false
    t.string "hospital_name", null: false
    t.text "diagnosis"
    t.datetime "created_at", null: false
    t.string "vaccine_type"
    t.index ["care_record_id"], name: "index_hospital_visits_on_care_record_id"
  end

  create_table "meal_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_meal_types_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_meal_types_on_user_id"
  end

  create_table "meal_units", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_meal_units_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_meal_units_on_user_id"
  end

  create_table "meals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "care_record_id", null: false
    t.decimal "amount", null: false
    t.decimal "completion_rate"
    t.datetime "created_at", null: false
    t.string "food_name"
    t.string "unit", default: "g"
    t.index ["care_record_id"], name: "index_meals_on_care_record_id"
  end

  create_table "medications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "care_record_id", null: false
    t.string "medicine_name", null: false
    t.datetime "created_at", null: false
    t.decimal "dosage_amount"
    t.string "dosage_unit"
    t.index ["care_record_id"], name: "index_medications_on_care_record_id"
  end

  create_table "medicine_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_medicine_types_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_medicine_types_on_user_id"
  end

  create_table "pet_record_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "pet_id", null: false
    t.integer "record_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pet_id", "record_type"], name: "index_pet_record_types_on_pet_id_and_record_type", unique: true
    t.index ["pet_id"], name: "index_pet_record_types_on_pet_id"
  end

  create_table "pets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.integer "species", default: 0, null: false
    t.string "species_note"
    t.date "birthday"
    t.string "icon_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "icon_storage_key"
    t.index ["user_id"], name: "index_pets_on_user_id"
  end

  create_table "temperatures", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "care_record_id", null: false
    t.decimal "temperature", null: false
    t.datetime "created_at", null: false
    t.index ["care_record_id"], name: "index_temperatures_on_care_record_id"
  end

  create_table "toilets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "care_record_id", null: false
    t.integer "kind", null: false
    t.integer "condition"
    t.datetime "created_at", null: false
    t.index ["care_record_id"], name: "index_toilets_on_care_record_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", default: "", null: false
    t.boolean "guest", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vaccine_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_vaccine_types_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_vaccine_types_on_user_id"
  end

  create_table "walks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "care_record_id", null: false
    t.integer "duration_minutes"
    t.decimal "distance"
    t.datetime "created_at", null: false
    t.index ["care_record_id"], name: "index_walks_on_care_record_id"
  end

  create_table "waters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "care_record_id", null: false
    t.decimal "amount", null: false
    t.datetime "created_at", null: false
    t.index ["care_record_id"], name: "index_waters_on_care_record_id"
  end

  create_table "weights", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "care_record_id", null: false
    t.decimal "weight", null: false
    t.datetime "created_at", null: false
    t.index ["care_record_id"], name: "index_weights_on_care_record_id"
  end

  add_foreign_key "attachments", "care_records"
  add_foreign_key "care_records", "pets"
  add_foreign_key "cares", "care_records"
  add_foreign_key "hospital_names", "users"
  add_foreign_key "hospital_visits", "care_records"
  add_foreign_key "meal_types", "users"
  add_foreign_key "meal_units", "users"
  add_foreign_key "meals", "care_records"
  add_foreign_key "medications", "care_records"
  add_foreign_key "medicine_types", "users"
  add_foreign_key "pet_record_types", "pets"
  add_foreign_key "pets", "users"
  add_foreign_key "temperatures", "care_records"
  add_foreign_key "toilets", "care_records"
  add_foreign_key "vaccine_types", "users"
  add_foreign_key "walks", "care_records"
  add_foreign_key "waters", "care_records"
  add_foreign_key "weights", "care_records"
end
