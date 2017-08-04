# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170804183747) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "admins", ["email"], name: "index_admins_on_email", unique: true, using: :btree
  add_index "admins", ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true, using: :btree

  create_table "compare_objects", force: :cascade do |t|
    t.string   "name"
    t.string   "emoticon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "post_id"
    t.string   "image"
  end

  create_table "counters", force: :cascade do |t|
    t.string   "reaction"
    t.integer  "x"
    t.integer  "y"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "post_id"
  end

  create_table "features", force: :cascade do |t|
    t.string   "description"
    t.integer  "template_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "file"
    t.integer  "post_id"
    t.string   "reaction"
    t.string   "name"
  end

  create_table "payments", force: :cascade do |t|
    t.string   "tx_id",      null: false
    t.integer  "user_id"
    t.float    "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "posts", force: :cascade do |t|
    t.string   "key"
    t.string   "title"
    t.time     "duration"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "background"
    t.integer  "comparisons"
    t.string   "video_id"
    t.string   "audio"
    t.string   "counter_color"
    t.integer  "user_id"
    t.string   "caption"
    t.string   "page_id"
    t.boolean  "live",           default: false
    t.datetime "start_time"
    t.integer  "category"
    t.string   "video"
    t.string   "image"
    t.integer  "template_id"
    t.string   "live_id"
    t.string   "process_id"
    t.boolean  "reload_browser", default: false
    t.integer  "status",         default: 0
  end

  create_table "templates", force: :cascade do |t|
    t.string   "path"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "image_count"
    t.boolean  "needs_background",  default: false
    t.boolean  "needs_image_names", default: false
    t.integer  "category",          default: 0
    t.string   "name"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                 default: "", null: false
    t.string   "encrypted_password",    default: "", null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "provider"
    t.string   "uid"
    t.string   "token"
    t.string   "name"
    t.integer  "role",                  default: 0
    t.date     "subscription_date"
    t.integer  "subscription_duration"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

end
