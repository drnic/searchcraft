# frozen_string_literal: true

module SearchCraft
  class Error < StandardError; end

  extend self

  def configure
    yield(config)
  end

  def config
    @config ||= Configuration.new
  end

  def database_ready?
    ActiveRecord::Base.connection.table_exists?("schema_migrations")
  rescue
    false
  end
end

require "active_record"

require_relative "searchcraft/version"
require_relative "searchcraft/configuration"
require_relative "searchcraft/annotate"
require_relative "searchcraft/depends_on"
require_relative "searchcraft/dump_schema"
require_relative "searchcraft/builder"
require_relative "searchcraft/model"
require_relative "searchcraft/view_hash_store"
require_relative "searchcraft/railtie" if defined?(Rails)
