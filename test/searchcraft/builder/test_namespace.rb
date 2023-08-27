# frozen_string_literal: true

require "test_helper"

module MyStore
  class NamespaceProduct < ActiveRecord::Base
    include SearchCraft::Model
  end

  class NamespaceProductBuilder < SearchCraft::Builder
    def view_select_sql
      # name column is 'Product #1', 'Product #2', etc.
      "SELECT 'Product #' || generate_series(1, 3) AS name;"
    end
  end
end

describe SearchCraft::Builder do
  it "supports namespaced builders" do
    # Connection to PostgreSQL server
    database_url = ENV.fetch("DATABASE_URL", "postgres://localhost:5432")
    ActiveRecord::Base.establish_connection(database_url)

    # Database name
    database_name = "searchcraft_gem_test_builder_namespace"

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

    assert_equal ["Product #1", "Product #2", "Product #3"], MyStore::NamespaceProduct.pluck(:name)

    # View name is based on namespace + class name
    assert_equal "my_store_namespace_products", MyStore::NamespaceProductBuilder.new.view_name
    assert_equal "my_store_namespace_products", MyStore::NamespaceProduct.table_name
  end
end
