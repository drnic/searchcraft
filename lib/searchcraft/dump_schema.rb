module SearchCraft::DumpSchema
  extend ActiveSupport::Concern

  # If in Rails, dump schema.rb after rebuilding views
  def dump_schema!
    return unless Rails.env.development?
    require "active_record/tasks/database_tasks"

    env = Rails.env
    db_configs = ActiveRecord::Base.configurations.configs_for(env_name: env)
    db_configs.each do |db_config|
      ActiveRecord::Tasks::DatabaseTasks.dump_schema(db_config, ActiveRecord.schema_format)
    end
  rescue ActiveRecord::NoDatabaseError
  rescue => e
    warn "Error dumping schema: #{e.message}"
    pp e.backtrace
  end
end
