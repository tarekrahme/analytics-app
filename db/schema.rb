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

ActiveRecord::Schema[7.0].define(version: 2023_07_06_100747) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.bigint "shopify_app_id", null: false
    t.datetime "occured_at"
    t.string "event_type"
    t.bigint "shop_id", null: false
    t.decimal "gross_amount", precision: 10, scale: 2
    t.date "billing_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_events_on_shop_id"
    t.index ["shopify_app_id", "shop_id", "event_type", "occured_at"], name: "index_events_on_app_and_shop_and_event_type_and_occured_at", unique: true
    t.index ["shopify_app_id"], name: "index_events_on_shopify_app_id"
  end

  create_table "plans", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.bigint "shopify_app_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shopify_app_id", "amount"], name: "index_plans_on_shopify_app_id_and_amount", unique: true
    t.index ["shopify_app_id"], name: "index_plans_on_shopify_app_id"
  end

  create_table "shopify_apps", force: :cascade do |t|
    t.string "name"
    t.string "provider_id"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_shopify_apps_on_user_id"
  end

  create_table "shops", force: :cascade do |t|
    t.bigint "shopify_app_id", null: false
    t.bigint "user_id", null: false
    t.string "shopify_domain"
    t.string "provider_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shopify_app_id"], name: "index_shops_on_shopify_app_id"
    t.index ["user_id"], name: "index_shops_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "shopify_app_id", null: false
    t.string "provider_id"
    t.string "interval"
    t.decimal "gross_amount", precision: 10, scale: 2
    t.decimal "net_amount", precision: 10, scale: 2
    t.decimal "shopify_fee", precision: 10, scale: 2
    t.datetime "provider_created_at"
    t.bigint "shop_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transaction_type"
    t.index ["shop_id"], name: "index_transactions_on_shop_id"
    t.index ["shopify_app_id"], name: "index_transactions_on_shopify_app_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "access_token"
    t.string "organisation_provider_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "events", "shopify_apps"
  add_foreign_key "events", "shops"
  add_foreign_key "plans", "shopify_apps"
  add_foreign_key "shopify_apps", "users"
  add_foreign_key "shops", "shopify_apps"
  add_foreign_key "shops", "users"
  add_foreign_key "transactions", "shopify_apps"
  add_foreign_key "transactions", "shops"
end
