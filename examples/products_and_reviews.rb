require "active_record"
require "pg"
require_relative "../lib/searchcraft"

show_hash_table = false

# Connection to PostgreSQL server
DATABASE_URL = ENV.fetch("DATABASE_URL", "postgres://localhost:5432")
ActiveRecord::Base.establish_connection(DATABASE_URL)

# Database name
database_name = "searchcraft_example_products_and_reviews"

# Drop the database if it already exists
if ActiveRecord::Base.connection.execute("SELECT 1 FROM pg_database WHERE datname = '#{database_name}'").any?
  ActiveRecord::Base.connection.drop_database(database_name)
  puts "Dropped existing database '#{database_name}'"
end

at_exit do
  ActiveRecord::Base.connection_pool.disconnect!
  ActiveRecord::Base.establish_connection(DATABASE_URL)
  ActiveRecord::Base.connection.drop_database(database_name)
  puts "\nExiting... Dropped database '#{database_name}'"
end

# Create the database
ActiveRecord::Base.connection.create_database(database_name)
puts "Created new database '#{database_name}'"
ActiveRecord::Base.establish_connection("#{DATABASE_URL}/#{database_name}")

# Migration for products table
class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.boolean :active, default: true, null: false
      # t.timestamps
    end
  end
end

class CreateCustomers < ActiveRecord::Migration[7.0]
  def change
    create_table :customers do |t|
      t.string :name, null: false
    end
  end
end

# Customers leave reviews for products
class CreateProductReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :product_reviews do |t|
      t.references :product, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :comment
      t.timestamps
    end
  end
end

# Running migrations
CreateProducts.new.change
CreateCustomers.new.change
CreateProductReviews.new.change

class Product < ActiveRecord::Base
  has_many :product_reviews, dependent: :destroy
  has_many :customers
end

class Customer < ActiveRecord::Base
end

class ProductReview < ActiveRecord::Base
  belongs_to :product
  belongs_to :customer
end

# Inserting seed data
laptop = Product.create!(name: "Laptop 3")
iphone = Product.create!(name: "iPhone 15")
Product.create!(name: "iPhone 2", active: false)
monopoly = Product.create!(name: "Monopoly")

# Printing all three models' rows
puts "Products:"
pp Product.all

# Some customers
drnic = Customer.create!(name: "Dr Nic")
banjo = Customer.create!(name: "Banjo")
maggie = Customer.create!(name: "Maggie")
charlie = Customer.create!(name: "Charlie")

# Customers leave some bad reviews a week ago
ProductReview.create!(product: laptop, customer: drnic, rating: 1, created_at: 1.week.ago)
ProductReview.create!(product: laptop, customer: banjo, rating: 1, created_at: 1.week.ago)
ProductReview.create!(product: iphone, customer: drnic, rating: 2, created_at: 1.week.ago)
ProductReview.create!(product: iphone, customer: banjo, rating: 2, created_at: 1.week.ago)
ProductReview.create!(product: monopoly, customer: banjo, rating: 2, created_at: 1.week.ago)
ProductReview.create!(product: monopoly, customer: maggie, rating: 3, created_at: 1.week.ago)
ProductReview.create!(product: monopoly, customer: charlie, rating: 1, created_at: 1.week.ago)

# Customers leave some good reviews yesterday
ProductReview.create!(product: laptop, customer: drnic, rating: 4, created_at: 1.day.ago)
ProductReview.create!(product: laptop, customer: banjo, rating: 4, created_at: 1.day.ago)
ProductReview.create!(product: laptop, customer: maggie, rating: 4, created_at: 1.day.ago)
ProductReview.create!(product: iphone, customer: drnic, rating: 5, created_at: 1.day.ago)
ProductReview.create!(product: iphone, customer: drnic, rating: 5, created_at: 1.day.ago)
ProductReview.create!(product: iphone, customer: maggie, rating: 5, created_at: 1.day.ago)

# Our model for the materialized view created by ProductSearchBuilder below
class ProductSearch < ActiveRecord::Base
  include SearchCraft::Model

  belongs_to :product, foreign_key: :product_id, primary_key: :id
end

# Initially, let's just return basic Product columns:
#  - id as product_id
#  - name as product_name
#  - active Products only
class ProductSearchBuilder < SearchCraft::Builder
  def view_scope
    Product
      .where(active: true) # only active products
      .order(:product_name)
      .select(
        "products.id AS product_id",
        "products.name AS product_name"
        # Or could use Arel:
        # Product.arel_table[:id].as("product_id"),
        # Product.arel_table[:name].as("product_name")
      )
  end
end

SearchCraft::Builder.rebuild_any_if_changed!
puts "\nViewHashStore now contains:" if show_hash_table
pp SearchCraft::ViewHashStore.all if show_hash_table

puts "\nDoes ProductSearch have a table/view in database? #{ProductSearch.table_exists?}"
puts "\nWhat does the SQL look like?"
puts ProductSearchBuilder.new.view_select_sql

puts "\nProductSearch rows only include active products:"
pp ProductSearch.all

puts "\nRedefine builder to use nextval and sequence for an id column:"
class ProductSearchBuilder < SearchCraft::Builder
  def view_scope # standard:disable Lint/DuplicateMethods
    Product
      .where(active: true) # only active products
      .order(:product_name)
      .select(
        "nextval('#{view_id_sequence_name}') AS id, " \
        "products.id AS product_id",
        "products.name AS product_name"
      )
  end
end

# Manually drop + create the materialized view
SearchCraft::Builder.rebuild_any_if_changed!
puts "\nViewHashStore now contains:" if show_hash_table
pp SearchCraft::ViewHashStore.all if show_hash_table

ProductSearch.reset_column_information # Not required in development or test environments
puts "\nProductSearch now has an id column:"
pp ProductSearch.all.reload

# Add basic review stats
class ProductSearchBuilder < SearchCraft::Builder
  def view_scope # standard:disable Lint/DuplicateMethods
    Product
      .where(active: true) # only active products
      .order(:product_name)
      .select(
        "nextval('#{view_id_sequence_name}') AS id, " \
        "products.id AS product_id",
        "products.name AS product_name",
        "(SELECT COUNT(*) FROM product_reviews WHERE product_reviews.product_id = products.id) AS reviews_count",
        "(SELECT AVG(rating) FROM product_reviews WHERE product_reviews.product_id = products.id) AS reviews_average"
      )
  end
end

SearchCraft::Builder.rebuild_any_if_changed!
ProductSearch.reset_column_information # Not required in development or test environments
puts "\nAdd basic review stats:"
pp ProductSearch.all.reload
pp ProductSearch.order(reviews_average: :desc)

# Review stats for latest customers' review only
class ProductSearchBuilder < SearchCraft::Builder
  def view_scope # standard:disable Lint/DuplicateMethods
    Product
      .where(active: true) # only active products
      .order(:product_name)
      .select(
        "products.id AS product_id",
        "products.name AS product_name",
        "(SELECT COUNT(*) FROM product_reviews WHERE product_reviews.product_id = products.id) AS reviews_count",
        "(SELECT AVG(rating) FROM product_reviews WHERE product_reviews.product_id = products.id) AS reviews_average",
        "(SELECT COUNT(DISTINCT product_reviews.customer_id) FROM product_reviews WHERE product_reviews.product_id = products.id) AS reviews_customers_count",
        "(SELECT AVG(latest_reviews.rating) FROM (SELECT DISTINCT ON (customer_id) rating FROM product_reviews WHERE product_reviews.product_id = products.id ORDER BY customer_id, created_at DESC) AS latest_reviews) AS reviews_average_for_latest"
      )
  end
end

SearchCraft::Builder.rebuild_any_if_changed!
ProductSearch.reset_column_information # Not required in development or test environments
puts "\nReview stats for latest customers' review only:"
pp ProductSearch.all.reload
