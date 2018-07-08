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

ActiveRecord::Schema.define(version: 20180708183426) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace"
    t.text     "body"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "admin_users", force: :cascade do |t|
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

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "big_pages", force: :cascade do |t|
    t.string   "name"
    t.string   "page_id"
    t.string   "image_url"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "fan_count",  default: 0
  end

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

  create_table "editors", force: :cascade do |t|
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

  add_index "editors", ["email"], name: "index_editors_on_email", unique: true, using: :btree
  add_index "editors", ["reset_password_token"], name: "index_editors_on_reset_password_token", unique: true, using: :btree

  create_table "extra_texts", force: :cascade do |t|
    t.string   "text"
    t.integer  "font_size"
    t.string   "color"
    t.integer  "position_x"
    t.integer  "position_y"
    t.integer  "post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.integer  "position_x"
    t.integer  "position_y"
    t.integer  "height"
    t.integer  "width"
  end

  create_table "links", force: :cascade do |t|
    t.string   "url"
    t.integer  "post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "live_streams", force: :cascade do |t|
    t.string   "page_id"
    t.integer  "post_id"
    t.string   "key"
    t.string   "video_id"
    t.string   "live_id"
    t.integer  "status",     default: 0, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "target",     default: 0
  end

  create_table "messages", force: :cascade do |t|
    t.text     "content"
    t.integer  "post_id"
    t.integer  "live_stream_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "moderators", force: :cascade do |t|
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

  add_index "moderators", ["email"], name: "index_moderators_on_email", unique: true, using: :btree
  add_index "moderators", ["reset_password_token"], name: "index_moderators_on_reset_password_token", unique: true, using: :btree

  create_table "payments", force: :cascade do |t|
    t.string   "tx_id",                  null: false
    t.integer  "user_id"
    t.float    "amount"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "status",     default: 0
    t.string   "payment_id",             null: false
  end

  create_table "posts", force: :cascade do |t|
    t.string   "title"
    t.time     "duration"
    t.datetime "created_at",                                                                          null: false
    t.datetime "updated_at",                                                                          null: false
    t.string   "background"
    t.integer  "comparisons"
    t.string   "audio"
    t.string   "counter_color"
    t.integer  "user_id"
    t.string   "caption"
    t.boolean  "live",            default: false
    t.datetime "start_time"
    t.integer  "category"
    t.string   "video"
    t.string   "image"
    t.integer  "template_id"
    t.boolean  "reload_browser",  default: false
    t.integer  "status",          default: 0
    t.string   "html"
    t.text     "default_message", default: "To make something like this, visit www.shurikenlive.com"
    t.datetime "started_at"
  end

  create_table "shared_posts", force: :cascade do |t|
    t.string   "shared_post_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "live_stream_id"
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

  create_table "user_templates", force: :cascade do |t|
    t.integer  "user_role"
    t.integer  "template_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                 default: "",    null: false
    t.string   "encrypted_password",    default: "",    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "provider"
    t.string   "uid"
    t.string   "token"
    t.string   "name"
    t.integer  "role",                  default: 0
    t.date     "subscription_date"
    t.integer  "subscription_duration"
    t.boolean  "banned",                default: false
    t.boolean  "premium_tried",         default: false
    t.integer  "free_videos_left",      default: 5
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

  create_table "videos", force: :cascade do |t|
    t.string   "file"
    t.integer  "post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
