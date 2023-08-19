require "active_record"
require "pg"
require_relative "../lib/searchcraft"

# Connection to PostgreSQL server
DATABASE_URL = ENV.fetch("DATABASE_URL", "postgres://localhost:5432")
ActiveRecord::Base.establish_connection(DATABASE_URL)

# Database name
database_name = "searchcraft_example_products_and_categories"

# Drop the database if it already exists
if ActiveRecord::Base.connection.execute("SELECT 1 FROM pg_database WHERE datname = '#{database_name}'").any?
  ActiveRecord::Base.connection.drop_database(database_name)
  puts "Dropped existing database '#{database_name}'"
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

# Migration for categories table
class CreateCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end

# Migration for product_categories join table
class CreateProductCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :product_categories do |t|
      t.references :product, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
  end
end

# Running migrations
CreateProducts.new.change
CreateCategories.new.change
CreateProductCategories.new.change

class Product < ActiveRecord::Base
  has_many :product_categories
  has_many :categories, through: :product_categories
end

class Category < ActiveRecord::Base
  has_many :product_categories
  has_many :products, through: :product_categories
end

class ProductCategory < ActiveRecord::Base
  belongs_to :product
  belongs_to :category
end

# Our model for the materialized view created by ProductSearchBuilder below
class ProductSearch < ActiveRecord::Base
  def read_only?
    true
  end

  belongs_to :product, foreign_key: :product_id, primary_key: :id
  belongs_to :category, foreign_key: :category_id, primary_key: :id
end

class ProductSearchBuilder < SearchCraft::Builder
  def view_scope
    Product
      .joins(:categories)
      .where(active: true) # only active products
      .where(categories: {active: true}) # only active categories
      .order(:product_name)
      .select(
        "products.id AS product_id, " \
        "products.name AS product_name, " \
        "categories.id AS category_id, " \
        "categories.name AS category_name"
        # Or could use Arel:
        # Product.arel_table[:id].as("product_id"),
        # Product.arel_table[:name].as("product_name"),
        # Category.arel_table[:id].as("category_id"),
        # Category.arel_table[:name].as("category_name")
      )
  end
end

# Inserting seed data
laptop = Product.create!(name: "Laptop 3")
iphone = Product.create!(name: "iPhone 15")
inactive_iphone = Product.create!(name: "iPhone 2", active: false)
monopoly = Product.create!(name: "Monopoly")
electronics = Category.create!(name: "Electronics")
phones = Category.create!(name: "Phones")
inactive_category = Category.create!(name: "Board Games", active: false)
ProductCategory.create!(product: laptop, category: electronics)
ProductCategory.create!(product: iphone, category: electronics)
ProductCategory.create!(product: iphone, category: phones)
ProductCategory.create!(product: inactive_iphone, category: electronics)
ProductCategory.create!(product: laptop, category: inactive_category)
ProductCategory.create!(product: monopoly, category: inactive_category)

# Printing all three models' rows
puts "Products:"
Product.all.each { |p| puts p.name }
puts "\nCategories:"
Category.all.each { |c| puts c.name }
puts "\nProduct Categories:"
ProductCategory.all.each { |pc| puts "Product: #{pc.product.name}, Category: #{pc.category.name}" }

# Manually create the materialized view
ProductSearchBuilder.new.create_view!

puts "\nDoes ProductSearch have a table/view in database? #{ProductSearch.table_exists?}"
puts ProductSearchBuilder.new.view_select_sql
exit 1 unless ProductSearch.table_exists?

puts "\nProductSearch rows only include active products and their active categories:"
pp ProductSearch.all
puts "\nSearch for Electronics:"
pp ProductSearch.where(category: electronics)
