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

ActiveRecord::Schema[8.1].define(version: 2026_09_10_010000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
    t.index ["record_type", "record_id", "name"], name: "idx_on_record_type_record_id_name_e9c38888ab"
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "idx_on_blob_id_variation_digest_f36bede0d9", unique: true
  end

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

  create_table "club_payout_destinations", force: :cascade do |t|
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.bigint "owner_id", null: false
    t.string "pix_key", null: false
    t.string "pix_key_type", null: false
    t.string "recipient_name", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["club_id"], name: "index_club_payout_destinations_on_club_id", unique: true
    t.index ["owner_id"], name: "index_club_payout_destinations_on_owner_id"
  end

  create_table "club_payouts", force: :cascade do |t|
    t.bigint "club_id", null: false
    t.bigint "club_payout_destination_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "failure_reason"
    t.decimal "gross_amount", precision: 10, scale: 2, null: false
    t.decimal "net_amount", precision: 10, scale: 2, null: false
    t.string "provider", default: "asaas", null: false
    t.string "provider_status"
    t.string "provider_transfer_id"
    t.bigint "requested_by_id", null: false
    t.string "status", default: "pending", null: false
    t.decimal "transfer_fee_amount", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["club_id"], name: "index_club_payouts_on_club_id"
    t.index ["club_payout_destination_id"], name: "index_club_payouts_on_club_payout_destination_id"
    t.index ["provider", "provider_transfer_id"], name: "index_club_payouts_on_provider_and_provider_transfer_id", unique: true, where: "(provider_transfer_id IS NOT NULL)"
    t.index ["requested_by_id"], name: "index_club_payouts_on_requested_by_id"
    t.index ["status"], name: "index_club_payouts_on_status"
    t.check_constraint "gross_amount > 0::numeric", name: "club_payouts_gross_amount_positive"
    t.check_constraint "net_amount > 0::numeric", name: "club_payouts_net_amount_positive"
  end

  create_table "clubs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "whatsapp_contact_number"
  end

  create_table "registration_payment_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "status", default: "pending", null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.integer "total_chip_amount", null: false
    t.bigint "tournament_registration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_registration_payment_groups_on_status"
    t.index ["tournament_registration_id"], name: "idx_on_tournament_registration_id_7a2647e908"
    t.check_constraint "total_amount >= 0::numeric", name: "registration_payment_groups_total_amount_non_negative"
    t.check_constraint "total_chip_amount >= 0", name: "registration_payment_groups_total_chips_non_negative"
  end

  create_table "registration_payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.decimal "charged_amount", precision: 10, scale: 2
    t.integer "chip_amount"
    t.datetime "created_at", null: false
    t.decimal "gateway_fee_amount", precision: 10, scale: 2
    t.decimal "net_amount", precision: 10, scale: 2
    t.datetime "paid_at"
    t.string "payment_method", null: false
    t.datetime "pix_expiration_date"
    t.text "pix_payload"
    t.text "pix_qr_code_image"
    t.string "provider", null: false
    t.string "provider_payment_id"
    t.string "provider_payment_url"
    t.string "provider_status"
    t.bigint "recorded_by_id", null: false
    t.bigint "registration_payment_group_id"
    t.string "status", default: "pending", null: false
    t.bigint "tournament_charge_option_id", null: false
    t.bigint "tournament_registration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "provider_payment_id"], name: "idx_on_provider_provider_payment_id_d5c7638595", unique: true, where: "(provider_payment_id IS NOT NULL)"
    t.index ["recorded_by_id"], name: "index_registration_payments_on_recorded_by_id"
    t.index ["registration_payment_group_id"], name: "index_registration_payments_on_registration_payment_group_id"
    t.index ["status"], name: "index_registration_payments_on_status"
    t.index ["tournament_charge_option_id"], name: "index_registration_payments_on_tournament_charge_option_id"
    t.index ["tournament_registration_id"], name: "index_registration_payments_on_tournament_registration_id"
    t.check_constraint "amount >= 0::numeric", name: "registration_payments_amount_non_negative"
    t.check_constraint "chip_amount IS NULL OR chip_amount >= 0", name: "registration_payments_chips_non_negative"
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

  create_table "tournament_prize_pools", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_tournament_prize_pools_on_tournament_id", unique: true
    t.check_constraint "total_amount > 0::numeric", name: "tournament_prize_pools_total_amount_positive"
  end

  create_table "tournament_prize_positions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "percentage", precision: 5, scale: 2, null: false
    t.integer "position", null: false
    t.bigint "tournament_prize_pool_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_prize_pool_id", "position"], name: "index_prize_positions_on_pool_and_position", unique: true
    t.index ["tournament_prize_pool_id"], name: "index_tournament_prize_positions_on_tournament_prize_pool_id"
    t.check_constraint "\"position\" > 0", name: "tournament_prize_positions_position_positive"
    t.check_constraint "percentage >= 0::numeric AND percentage <= 100::numeric", name: "tournament_prize_positions_percentage_in_range"
  end

  create_table "tournament_registrations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "status", default: "pending", null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["status"], name: "index_tournament_registrations_on_status"
    t.index ["tournament_id", "user_id"], name: "index_tournament_registrations_on_tournament_id_and_user_id", unique: true
    t.index ["tournament_id"], name: "index_tournament_registrations_on_tournament_id"
    t.index ["user_id"], name: "index_tournament_registrations_on_user_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.string "google_place_id"
    t.string "invite_token", null: false
    t.string "location", null: false
    t.integer "max_players", null: false
    t.string "name", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "posted", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_tournaments_on_lower_name", unique: true
    t.index ["club_id", "starts_at"], name: "index_tournaments_on_club_id_and_starts_at"
    t.index ["club_id"], name: "index_tournaments_on_club_id"
    t.index ["google_place_id"], name: "index_tournaments_on_google_place_id"
    t.index ["invite_token"], name: "index_tournaments_on_invite_token", unique: true
    t.index ["starts_at"], name: "index_tournaments_on_starts_at"
    t.index ["status"], name: "index_tournaments_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "asaas_customer_id"
    t.string "cpf"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "profile_completed_at"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["asaas_customer_id"], name: "index_users_on_asaas_customer_id", unique: true, where: "(asaas_customer_id IS NOT NULL)"
    t.index ["cpf"], name: "index_users_on_cpf", unique: true, where: "(cpf IS NOT NULL)"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, where: "((provider IS NOT NULL) AND (uid IS NOT NULL))"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blind_levels", "tournaments"
  add_foreign_key "club_memberships", "clubs"
  add_foreign_key "club_memberships", "users"
  add_foreign_key "club_payout_destinations", "clubs"
  add_foreign_key "club_payout_destinations", "users", column: "owner_id"
  add_foreign_key "club_payouts", "club_payout_destinations"
  add_foreign_key "club_payouts", "clubs"
  add_foreign_key "club_payouts", "users", column: "requested_by_id"
  add_foreign_key "registration_payment_groups", "tournament_registrations"
  add_foreign_key "registration_payments", "registration_payment_groups"
  add_foreign_key "registration_payments", "tournament_charge_options"
  add_foreign_key "registration_payments", "tournament_registrations"
  add_foreign_key "registration_payments", "users", column: "recorded_by_id"
  add_foreign_key "tournament_charge_options", "blind_levels", column: "available_from_level_id"
  add_foreign_key "tournament_charge_options", "blind_levels", column: "available_until_level_id"
  add_foreign_key "tournament_charge_options", "tournaments"
  add_foreign_key "tournament_clock_events", "blind_levels", column: "from_blind_level_id"
  add_foreign_key "tournament_clock_events", "blind_levels", column: "to_blind_level_id"
  add_foreign_key "tournament_clock_events", "tournaments"
  add_foreign_key "tournament_clock_states", "blind_levels", column: "current_blind_level_id", on_delete: :cascade
  add_foreign_key "tournament_clock_states", "tournaments", on_delete: :cascade
  add_foreign_key "tournament_prize_pools", "tournaments"
  add_foreign_key "tournament_prize_positions", "tournament_prize_pools"
  add_foreign_key "tournament_registrations", "tournaments"
  add_foreign_key "tournament_registrations", "users"
  add_foreign_key "tournaments", "clubs"
end
