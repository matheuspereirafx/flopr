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

ActiveRecord::Schema[8.1].define(version: 2026_08_12_202000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "blind_levels", force: :cascade do |t|
    t.integer "ante", default: 0, null: false
    t.integer "big_blind", null: false
    t.datetime "created_at", null: false
    t.integer "duration_minutes", null: false
    t.integer "level", null: false
    t.integer "small_blind", null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id", "level"], name: "index_blind_levels_on_tournament_id_and_level", unique: true
    t.index ["tournament_id"], name: "index_blind_levels_on_tournament_id"
  end

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

  create_table "tournament_charge_options", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.decimal "amount", precision: 10, scale: 2
    t.bigint "available_from_level_id"
    t.bigint "available_until_level_id"
    t.integer "chip_amount"
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["available_from_level_id"], name: "index_tournament_charge_options_on_available_from_level_id"
    t.index ["available_until_level_id"], name: "index_tournament_charge_options_on_available_until_level_id"
    t.index ["tournament_id", "kind"], name: "index_tournament_charge_options_on_tournament_id_and_kind", unique: true
    t.index ["tournament_id"], name: "index_tournament_charge_options_on_tournament_id"
    t.check_constraint "amount IS NULL OR amount >= 0::numeric", name: "tournament_charge_options_amount_non_negative"
    t.check_constraint "chip_amount IS NULL OR chip_amount >= 0", name: "tournament_charge_options_chips_non_negative"
  end

  create_table "tournament_clock_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "from_blind_level_id", null: false
    t.string "kind", null: false
    t.datetime "occurred_at", null: false
    t.bigint "to_blind_level_id", null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_blind_level_id"], name: "index_tournament_clock_events_on_from_blind_level_id"
    t.index ["to_blind_level_id"], name: "index_tournament_clock_events_on_to_blind_level_id"
    t.index ["tournament_id", "occurred_at"], name: "index_tournament_clock_events_on_tournament_id_and_occurred_at"
    t.index ["tournament_id"], name: "index_tournament_clock_events_on_tournament_id"
  end

  create_table "tournament_clock_states", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "current_blind_level_id", null: false
    t.integer "overtime_elapsed_seconds", default: 0, null: false
    t.datetime "overtime_started_at"
    t.datetime "paused_at"
    t.integer "remaining_seconds", default: 0, null: false
    t.datetime "started_at"
    t.string "status", default: "not_started", null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["current_blind_level_id"], name: "index_tournament_clock_states_on_current_blind_level_id"
    t.index ["tournament_id"], name: "index_tournament_clock_states_on_tournament_id", unique: true
    t.check_constraint "overtime_elapsed_seconds >= 0", name: "tournament_clock_states_overtime_elapsed_seconds_non_negative"
    t.check_constraint "remaining_seconds >= 0", name: "tournament_clock_states_remaining_seconds_non_negative"
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
    t.index "lower((name)::text)", name: "index_tournaments_on_lower_name", unique: true
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

  add_foreign_key "blind_levels", "tournaments"
  add_foreign_key "club_memberships", "clubs"
  add_foreign_key "club_memberships", "users"
  add_foreign_key "tournament_charge_options", "blind_levels", column: "available_from_level_id"
  add_foreign_key "tournament_charge_options", "blind_levels", column: "available_until_level_id"
  add_foreign_key "tournament_charge_options", "tournaments"
  add_foreign_key "tournament_clock_events", "blind_levels", column: "from_blind_level_id"
  add_foreign_key "tournament_clock_events", "blind_levels", column: "to_blind_level_id"
  add_foreign_key "tournament_clock_events", "tournaments"
  add_foreign_key "tournament_clock_states", "blind_levels", column: "current_blind_level_id", on_delete: :cascade
  add_foreign_key "tournament_clock_states", "tournaments", on_delete: :cascade
  add_foreign_key "tournaments", "clubs"
end
