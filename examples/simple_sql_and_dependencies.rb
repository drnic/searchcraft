require "active_record"
require "pg"
require_relative "../lib/searchcraft"

show_hash_table = false

# Connection to PostgreSQL server
DATABASE_URL = ENV.fetch("DATABASE_URL", "postgres://localhost:5432")
ActiveRecord::Base.establish_connection(DATABASE_URL)

# Database name
database_name = "searchcraft_example_simple_sql_and_dependencies"

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

class NumberBuilder < SearchCraft::Builder
  def view_select_sql
    # Write SQL that produces 5 rows, with a 'number' column containing the number of the row
    "SELECT generate_series(1, 5) AS number;"
  end
end

class Number < ActiveRecord::Base
  include SearchCraft::Model
end

class SquaredBuilder < SearchCraft::Builder
  depends_on "NumberBuilder"

  def view_select_sql
    "SELECT number, number * number AS squared FROM #{Number.table_name};"
  end
end

class Squared < ActiveRecord::Base
  include SearchCraft::Model
end

# Weird implementation of Cubed just to depend on two builders
class CubedBuilder < SearchCraft::Builder
  depends_on "SquaredBuilder"

  def view_select_sql
    "SELECT number, squared, number * squared AS cubed FROM #{Squared.table_name};"
  end
end

class Cubed < ActiveRecord::Base
  include SearchCraft::Model
end

SearchCraft::Builder.rebuild_any_if_changed!
puts "\nViewHashStore now contains:" if show_hash_table
pp SearchCraft::ViewHashStore.all if show_hash_table

pp Number.all
pp Squared.all
pp Cubed.all
