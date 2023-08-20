ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Run additional setup code after fixtures are loaded
  setup do
    ProductSearchBuilder.new.recreate_view_if_changed!
    OnsaleSearchBuilder.new.recreate_view_if_changed!
  end
end
