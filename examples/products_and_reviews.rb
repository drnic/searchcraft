require "active_record"
require "pg"
require_relative "../lib/searchcraft"

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

      t.timestamps
    end
  end
end

# Running migrations
CreateProducts.new.change

class Product < ActiveRecord::Base
end

# Inserting seed data
Product.create!(name: "Laptop 3")
Product.create!(name: "iPhone 15")
Product.create!(name: "iPhone 2", active: false)
Product.create!(name: "Monopoly")

# Printing all three models' rows
puts "Products:"
Product.all.each { |p| puts p.name }

# Our model for the materialized view created by ProductSearchBuilder below
class ProductSearch < ActiveRecord::Base
  include SearchCraft::Model

  belongs_to :product, foreign_key: :product_id, primary_key: :id
end

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
puts "\nViewHashStore now contains:"
pp SearchCraft::ViewHashStore.all

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
puts "\nViewHashStore now contains:"
pp SearchCraft::ViewHashStore.all

ProductSearch.reset_column_information # Not required in development or test environments
puts "\nProductSearch now has an id column:"
pp ProductSearch.all.reload
