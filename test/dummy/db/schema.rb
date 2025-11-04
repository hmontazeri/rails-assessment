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

ActiveRecord::Schema[8.1].define(version: 2025_02_15_000000) do
  create_table "rails_assessment_responses", force: :cascade do |t|
    t.json "answers", default: {}
    t.string "assessment_slug", null: false
    t.datetime "created_at", null: false
    t.string "result"
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index [ "assessment_slug" ], name: "index_rails_assessment_responses_on_assessment_slug"
    t.index [ "created_at" ], name: "index_rails_assessment_responses_on_created_at"
    t.index [ "uuid" ], name: "index_rails_assessment_responses_on_uuid", unique: true
  end
end
