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

ActiveRecord::Schema[7.1].define(version: 2025_12_28_194358) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bulk_uploads", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "total_rows", default: 0
    t.integer "successful_rows", default: 0
    t.integer "failed_rows", default: 0
    t.jsonb "error_details", default: []
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "processed_count", default: 0, null: false
    t.integer "current_row"
    t.datetime "started_at"
    t.index ["created_at"], name: "index_bulk_uploads_on_created_at"
    t.index ["status"], name: "index_bulk_uploads_on_status"
    t.index ["user_id"], name: "index_bulk_uploads_on_user_id"
  end

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
    t.string "sender_email"
    t.text "address"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "phone"
    t.boolean "exchange", default: false, null: false
    t.date "loading_date"
    t.bigint "region_id"
    t.bigint "commune_id"
    t.integer "status", default: 0, null: false
    t.datetime "cancelled_at"
    t.text "cancellation_reason"
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "tracking_code", null: false
    t.integer "previous_status"
    t.jsonb "status_history", default: []
    t.string "location"
    t.integer "attempts_count", default: 0
    t.bigint "assigned_courier_id"
    t.text "proof", comment: "DEPRECATED: Use proof_photos Active Storage attachment instead. This column stored base64 JSON (inefficient). Will be removed in future version after data migration."
    t.datetime "reprogramed_to"
    t.text "reprogram_motive"
    t.datetime "picked_at"
    t.datetime "shipped_at"
    t.datetime "delivered_at"
    t.boolean "admin_override", default: false
    t.bigint "bulk_upload_id"
    t.string "company_name"
    t.datetime "assigned_at"
    t.bigint "assigned_by_id"
    t.index ["assigned_by_id"], name: "index_packages_on_assigned_by_id"
    t.index ["assigned_courier_id", "assigned_at"], name: "index_packages_on_assigned_courier_id_and_assigned_at"
    t.index ["assigned_courier_id", "delivered_at"], name: "index_packages_on_assigned_courier_and_delivered_at", comment: "Optimizes Driver#today_deliveries queries (QA audit fix)"
    t.index ["assigned_courier_id"], name: "index_packages_on_assigned_courier_id"
    t.index ["bulk_upload_id"], name: "index_packages_on_bulk_upload_id"
    t.index ["commune_id"], name: "index_packages_on_commune_id"
    t.index ["created_at"], name: "index_packages_on_created_at"
    t.index ["exchange"], name: "index_packages_on_exchange"
    t.index ["loading_date"], name: "index_packages_on_loading_date"
    t.index ["region_id", "commune_id"], name: "index_packages_on_region_and_commune"
    t.index ["region_id"], name: "index_packages_on_region_id"
    t.index ["status", "assigned_courier_id"], name: "index_packages_on_status_and_assigned_courier_id"
    t.index ["status", "loading_date"], name: "index_packages_on_status_and_loading_date"
    t.index ["status"], name: "index_packages_on_status"
    t.index ["tracking_code"], name: "index_packages_on_tracking_code", unique: true
    t.index ["tracking_code"], name: "index_packages_on_tracking_code_trigram", opclass: :gin_trgm_ops, using: :gin, comment: "Trigram index for fast ILIKE searches on tracking_code"
    t.index ["user_id", "status"], name: "index_packages_on_user_id_and_status"
    t.index ["user_id"], name: "index_packages_on_user_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_regions_on_name", unique: true
  end

  create_table "routes", force: :cascade do |t|
    t.bigint "driver_id", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at"
    t.integer "packages_delivered", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.integer "closed_by_id"
    t.text "forced_close_reason"
    t.datetime "forced_closed_at"
    t.index ["closed_by_id"], name: "index_routes_on_closed_by_id"
    t.index ["driver_id", "started_at"], name: "index_routes_on_driver_and_started"
    t.index ["driver_id", "status"], name: "index_routes_on_driver_and_status"
    t.index ["driver_id"], name: "index_routes_on_driver_id"
    t.index ["forced_closed_at"], name: "index_routes_on_forced_closed_at"
    t.index ["status"], name: "index_routes_on_status"
  end

  create_table "settings", force: :cascade do |t|
    t.boolean "require_driver_authorization", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "customer_visible_pending_pickup", default: true, null: false
    t.boolean "customer_visible_in_warehouse", default: true, null: false
    t.boolean "customer_visible_in_transit", default: true, null: false
    t.boolean "customer_visible_rescheduled", default: true, null: false
    t.boolean "customer_visible_delivered", default: true, null: false
    t.boolean "customer_visible_return", default: true, null: false
    t.boolean "customer_visible_cancelled", default: true, null: false
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
    t.boolean "show_logo_on_labels", default: true
    t.string "rut"
    t.string "phone"
    t.string "company"
    t.boolean "active", default: true, null: false
    t.decimal "delivery_charge", precision: 10, scale: 2, default: "0.0", null: false
    t.string "type"
    t.string "vehicle_plate"
    t.string "vehicle_model"
    t.integer "vehicle_capacity"
    t.bigint "assigned_zone_id"
    t.boolean "ready_for_route", default: false, null: false
    t.integer "route_status", default: 0, null: false
    t.datetime "route_started_at"
    t.datetime "route_ended_at"
    t.string "name"
    t.index ["assigned_zone_id"], name: "index_users_on_assigned_zone_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone"
    t.index ["ready_for_route"], name: "index_users_on_ready_for_route"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role", "active"], name: "index_users_on_role_and_active"
    t.index ["role"], name: "index_users_on_role"
    t.index ["route_status"], name: "index_users_on_route_status"
    t.index ["rut"], name: "index_users_on_rut", unique: true, where: "(rut IS NOT NULL)"
    t.index ["type", "route_status"], name: "index_users_on_type_and_route_status"
    t.index ["type"], name: "index_users_on_type"
    t.index ["vehicle_plate"], name: "index_users_on_vehicle_plate", unique: true, where: "(vehicle_plate IS NOT NULL)"
  end

  create_table "zones", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "region_id"
    t.jsonb "communes", default: []
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_zones_on_active"
    t.index ["name"], name: "index_zones_on_name", unique: true
    t.index ["region_id"], name: "index_zones_on_region_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bulk_uploads", "users"
  add_foreign_key "communes", "regions"
  add_foreign_key "packages", "bulk_uploads"
  add_foreign_key "packages", "communes"
  add_foreign_key "packages", "regions"
  add_foreign_key "packages", "users"
  add_foreign_key "packages", "users", column: "assigned_by_id"
  add_foreign_key "packages", "users", column: "assigned_courier_id"
  add_foreign_key "routes", "users", column: "closed_by_id"
  add_foreign_key "routes", "users", column: "driver_id"
  add_foreign_key "users", "zones", column: "assigned_zone_id"
  add_foreign_key "zones", "regions"
end
