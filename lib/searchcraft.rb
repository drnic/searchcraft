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

  def dependencies_ready?
    Builder.builders_to_rebuild.all? do |builder_class|
      builder_class.new.dependencies_ready?
    end
  end

  def debug?
    config.debug
  end

  def load_tasks
    return if @tasks_loaded

    Dir[File.join(File.dirname(__FILE__), "tasks", "**/*.rake")].each do |rake|
      load rake
    end

    @tasks_loaded = true
  end
end

require "active_record"

require_relative "searchcraft/version"
require_relative "searchcraft/configuration"
require_relative "searchcraft/annotate"
require_relative "searchcraft/depends_on"
require_relative "searchcraft/dump_schema"
require_relative "searchcraft/text_search"
require_relative "searchcraft/model"
require_relative "searchcraft/builder"
require_relative "searchcraft/view_hash_store"
require_relative "searchcraft/railtie" if defined?(Rails)
