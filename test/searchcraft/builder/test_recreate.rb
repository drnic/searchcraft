# frozen_string_literal: true

describe SearchCraft::Builder do
  it "recreate indexes" do
    # Connection to PostgreSQL server
    database_url = ENV.fetch("DATABASE_URL", "postgres://localhost:5432")
    ActiveRecord::Base.establish_connection(database_url)

    # Database name
    database_name = "searchcraft_gem_test_builder_recreate_indexes"

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

    SearchCraft::Builder.recreate_indexes!
  end
end
