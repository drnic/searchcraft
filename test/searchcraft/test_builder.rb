# frozen_string_literal: true

require "test_helper"

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

describe SearchCraft::Builder do
  it "ok" do
    # Connection to PostgreSQL server
    database_url = ENV.fetch("DATABASE_URL", "postgres://localhost:5432")
    ActiveRecord::Base.establish_connection(database_url)

    # Database name
    database_name = "searchcraft_gem_builder_test"

    begin
      ActiveRecord::Base.connection.drop_database(database_name)
      puts "Dropped existing database '#{database_name}'"
    rescue ActiveRecord::NoDatabaseError
    end

    at_exit do
      ActiveRecord::Base.connection_pool.disconnect!
      ActiveRecord::Base.establish_connection(database_url)
      ActiveRecord::Base.connection.drop_database(database_name)
      puts "\nExiting... Dropped database '#{database_name}'"
    end

    # Create the database
    ActiveRecord::Base.connection.create_database(database_name)
    puts "Created new database '#{database_name}'"
    ActiveRecord::Base.establish_connection("#{database_url}/#{database_name}")

    SearchCraft::Builder.rebuild_any_if_changed!

    assert_equal [1, 2, 3, 4, 5], Number.pluck(:number)

    assert_equal [1, 2, 3, 4, 5], Squared.pluck(:number)
    assert_equal [1, 4, 9, 16, 25], Squared.pluck(:squared)

    assert_equal [1, 2, 3, 4, 5].map { |n| n * n * n }, Cubed.pluck(:cubed)
  end
end
