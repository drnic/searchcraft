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

ActiveRecord::Schema[7.0].define(version: 2023_08_20_075247) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "product_categories", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_product_categories_on_category_id"
    t.index ["product_id"], name: "index_product_categories_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "search_craft_view_hash_stores", id: :serial, force: :cascade do |t|
    t.string "view_name", limit: 255, null: false
    t.string "view_sql_hash", limit: 255, null: false
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "now()" }, null: false
  end

  add_foreign_key "product_categories", "categories"
  add_foreign_key "product_categories", "products"

  create_view "product_searches", materialized: true, sql_definition: <<-SQL
      SELECT products.id AS product_id,
      products.name AS product_name,
      categories.id AS category_id,
      categories.name AS category_name
     FROM ((products
       JOIN product_categories ON ((product_categories.product_id = products.id)))
       JOIN categories ON ((categories.id = product_categories.category_id)))
    WHERE ((products.active = true) AND (categories.active = true))
    ORDER BY products.name;
  SQL
  add_index "product_searches", ["category_id"], name: "idx_product_searches_category_id"
end
