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

ActiveRecord::Schema[7.1].define(version: 2025_11_18_010644) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "communes", force: :cascade do |t|
    t.string "name"
    t.bigint "region_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_communes_on_name"
    t.index ["region_id", "name"], name: "index_communes_on_region_id_and_name", unique: true
    t.index ["region_id"], name: "index_communes_on_region_id"
  end

  create_table "packages", force: :cascade do |t|
    t.string "customer_name"
    t.string "company"
    t.text "address"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "phone"
    t.boolean "exchange", default: false, null: false
    t.date "pickup_date"
    t.bigint "region_id"
    t.bigint "commune_id"
    t.integer "status", default: 0, null: false
    t.datetime "cancelled_at"
    t.text "cancellation_reason"
    t.index ["commune_id"], name: "index_packages_on_commune_id"
    t.index ["created_at"], name: "index_packages_on_created_at"
    t.index ["exchange"], name: "index_packages_on_exchange"
    t.index ["pickup_date"], name: "index_packages_on_pickup_date"
    t.index ["region_id", "commune_id"], name: "index_packages_on_region_and_commune"
    t.index ["region_id"], name: "index_packages_on_region_id"
    t.index ["status", "pickup_date"], name: "index_packages_on_status_and_pickup_date"
    t.index ["status"], name: "index_packages_on_status"
    t.index ["user_id", "status"], name: "index_packages_on_user_id_and_status"
    t.index ["user_id"], name: "index_packages_on_user_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_regions_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.integer "role", default: 1, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "communes", "regions"
  add_foreign_key "packages", "communes"
  add_foreign_key "packages", "regions"
  add_foreign_key "packages", "users"
end
