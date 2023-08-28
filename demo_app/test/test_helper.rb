ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

require "minitest/autorun"
require "minitest/spec"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Run additional setup code after fixtures are loaded
  setup do
    SearchCraft::Builder.rebuild_any_if_changed!
    SearchCraft::Model.refresh_all!
  end
end
