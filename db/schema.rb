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

ActiveRecord::Schema[8.1].define(version: 2026_08_04_202347) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "club_memberships", force: :cascade do |t|
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.string "role", default: "player", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["club_id", "user_id"], name: "index_club_memberships_on_club_id_and_user_id", unique: true
    t.index ["club_id"], name: "index_club_memberships_on_club_id"
    t.index ["user_id"], name: "index_club_memberships_on_user_id"
  end

  create_table "clubs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "whatsapp_contact_number"
  end

  create_table "tournaments", force: :cascade do |t|
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.string "location", null: false
    t.integer "max_players", null: false
    t.string "name", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "posted", null: false
    t.datetime "updated_at", null: false
    t.index ["club_id", "starts_at"], name: "index_tournaments_on_club_id_and_starts_at"
    t.index ["club_id"], name: "index_tournaments_on_club_id"
    t.index ["starts_at"], name: "index_tournaments_on_starts_at"
    t.index ["status"], name: "index_tournaments_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "club_memberships", "clubs"
  add_foreign_key "club_memberships", "users"
  add_foreign_key "tournaments", "clubs"
end
