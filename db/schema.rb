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

ActiveRecord::Schema[8.1].define(version: 2026_10_16_123000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "films", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.integer "runtime"
    t.text "synopsis"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["external_id"], name: "index_films_on_external_id", unique: true
  end

  create_table "screenings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.bigint "film_id", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
    t.index ["external_id"], name: "index_screenings_on_external_id", unique: true
    t.index ["film_id"], name: "index_screenings_on_film_id"
    t.index ["starts_at"], name: "index_screenings_on_starts_at"
    t.index ["venue_id"], name: "index_screenings_on_venue_id"
  end

  create_table "sync_logs", force: :cascade do |t|
    t.string "action"
    t.integer "attempt"
    t.datetime "created_at", null: false
    t.string "error_class"
    t.text "error_message"
    t.string "external_id"
    t.datetime "finished_at"
    t.string "log_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "page"
    t.string "record_type"
    t.datetime "started_at", null: false
    t.string "status", null: false
    t.bigint "sync_run_id", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "external_id"], name: "index_sync_logs_on_record_type_and_external_id"
    t.index ["sync_run_id", "page"], name: "index_sync_logs_on_sync_run_id_and_page"
    t.index ["sync_run_id", "status"], name: "index_sync_logs_on_sync_run_id_and_status"
    t.index ["sync_run_id"], name: "index_sync_logs_on_sync_run_id"
  end

  create_table "sync_runs", force: :cascade do |t|
    t.integer "completed_pages", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.text "error_message"
    t.datetime "finished_at"
    t.string "status", default: "running", null: false
    t.integer "total_pages"
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_sync_runs_on_running_status", unique: true, where: "((status)::text = 'running'::text)"
  end

  create_table "venues", force: :cascade do |t|
    t.string "address"
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_venues_on_external_id", unique: true
  end

  add_foreign_key "screenings", "films"
  add_foreign_key "screenings", "venues"
  add_foreign_key "sync_logs", "sync_runs"
end
