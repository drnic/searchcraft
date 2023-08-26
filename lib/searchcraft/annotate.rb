module SearchCraft::Annotate
  extend ActiveSupport::Concern

  included do
    # If using annotate gem, then automatically annotate models after rebuilding views
    def annotate_models!
      return unless Object.const_defined?(:Annotate)

      require "rake/task" unless Object.const_defined?("Rake::Task")
      Annotate.load_tasks unless Rake::Task[:annotate_models]

      Rake::Task[:annotate_models].invoke
    end
  end
end
