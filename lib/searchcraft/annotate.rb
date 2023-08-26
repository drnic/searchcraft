module SearchCraft::Annotate
  include ActiveSupport::Concern

  def annotate_models!
    return unless Object.const_defined?(:Annotate)
    Annotate.load_tasks unless Rake::Task[:annotate_models]
    Rake::Task[:annotate_models].invoke
  end
end
