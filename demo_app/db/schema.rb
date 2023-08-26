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

ActiveRecord::Schema[7.0].define(version: 2023_08_25_004026) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "colors", force: :cascade do |t|
    t.string "label", null: false
    t.string "css_class", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
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

  create_table "product_colors", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "color_id", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["color_id"], name: "index_product_colors_on_color_id"
    t.index ["product_id"], name: "index_product_colors_on_product_id"
  end

  create_table "product_prices", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.integer "base_price", null: false
    t.integer "sale_price"
    t.string "currency", default: "AUD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_prices_on_product_id"
  end

  create_table "product_reviews", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "customer_id", null: false
    t.integer "rating"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_product_reviews_on_customer_id"
    t.index ["product_id"], name: "index_product_reviews_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_url"
  end

  create_table "search_craft_view_hash_stores", id: :serial, force: :cascade do |t|
    t.string "view_name", limit: 255, null: false
    t.string "view_sql_hash", limit: 255, null: false
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "now()" }, null: false
  end

  add_foreign_key "product_categories", "categories"
  add_foreign_key "product_categories", "products"
  add_foreign_key "product_colors", "colors"
  add_foreign_key "product_colors", "products"
  add_foreign_key "product_prices", "products"
  add_foreign_key "product_reviews", "customers"
  add_foreign_key "product_reviews", "products"

  create_view "product_searches", materialized: true, sql_definition: <<-SQL
      SELECT 6 AS number,
      products.id AS product_id,
      products.name AS product_name,
      products.image_url,
      product_prices.base_price,
      product_prices.sale_price,
      product_prices.currency,
      COALESCE(product_prices.sale_price, product_prices.base_price) AS price,
      ( SELECT count(*) AS count
             FROM product_reviews
            WHERE (product_reviews.product_id = products.id)) AS reviews_count,
      ( SELECT avg(product_reviews.rating) AS avg
             FROM product_reviews
            WHERE (product_reviews.product_id = products.id)) AS reviews_average,
      ( SELECT count(DISTINCT product_reviews.customer_id) AS count
             FROM product_reviews
            WHERE (product_reviews.product_id = products.id)) AS customer_reviews_count,
      ( SELECT avg(latest_reviews.rating) AS avg
             FROM ( SELECT DISTINCT ON (product_reviews.customer_id) product_reviews.rating
                     FROM product_reviews
                    WHERE (product_reviews.product_id = products.id)
                    ORDER BY product_reviews.customer_id, product_reviews.created_at DESC) latest_reviews) AS average_review_for_latest,
      ( SELECT sum(latest_reviews.rating) AS sum
             FROM ( SELECT DISTINCT ON (product_reviews.customer_id) product_reviews.rating
                     FROM product_reviews
                    WHERE (product_reviews.product_id = products.id)
                    ORDER BY product_reviews.customer_id, product_reviews.created_at DESC) latest_reviews) AS total_review_for_latest,
      ( SELECT count(latest_reviews.rating) AS count
             FROM ( SELECT DISTINCT ON (product_reviews.customer_id) product_reviews.rating
                     FROM product_reviews
                    WHERE (product_reviews.product_id = products.id)
                    ORDER BY product_reviews.customer_id, product_reviews.created_at DESC) latest_reviews) AS number_review_for_latest
     FROM (products
       JOIN product_prices ON ((product_prices.product_id = products.id)))
    WHERE (products.active = true)
    ORDER BY products.name;
  SQL
end
