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

ActiveRecord::Schema[8.0].define(version: 2026_07_31_090100) do
  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", default: "bank", null: false
    t.string "institution"
    t.string "currency", default: "MGA", null: false
    t.bigint "opening_balance_cents", default: 0, null: false
    t.string "color"
    t.text "notes"
    t.boolean "archived", default: false, null: false
    t.string "life_area", default: "personal", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["life_area", "archived"], name: "index_accounts_on_life_area_and_archived"
  end

  create_table "notes", force: :cascade do |t|
    t.string "title", null: false
    t.text "body"
    t.string "life_area", null: false
    t.boolean "pinned", default: false, null: false
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["life_area", "pinned"], name: "index_notes_on_life_area_and_pinned"
    t.index ["project_id"], name: "index_notes_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "life_area", null: false
    t.string "status", default: "active", null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["life_area", "status"], name: "index_projects_on_life_area_and_status"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.text "details"
    t.string "life_area", null: false
    t.string "status", default: "todo", null: false
    t.string "priority", default: "normal", null: false
    t.date "due_on"
    t.datetime "completed_at"
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["due_on"], name: "index_tasks_on_due_on"
    t.index ["life_area", "status"], name: "index_tasks_on_life_area_and_status"
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "transfer_account_id"
    t.string "kind", default: "expense", null: false
    t.bigint "amount_cents", null: false
    t.date "occurred_on", null: false
    t.string "category"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "occurred_on"], name: "index_transactions_on_account_id_and_occurred_on"
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["kind", "category"], name: "index_transactions_on_kind_and_category"
    t.index ["occurred_on"], name: "index_transactions_on_occurred_on"
    t.index ["transfer_account_id"], name: "index_transactions_on_transfer_account_id"
  end

  add_foreign_key "notes", "projects"
  add_foreign_key "tasks", "projects"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "accounts", column: "transfer_account_id"
end
