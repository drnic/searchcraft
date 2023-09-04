namespace :searchcraft do
  desc "Refresh searchcraft materialized views"
  task refresh: :environment do
    SearchCraft::Builder.rebuild_any_if_changed!
    require "benchmark"
    SearchCraft.config.explicit_model_class_names.each do |model_class_name|
      klass = model_class_name.constantize
      puts "Refreshing materialized views for #{klass.name}"
      puts Benchmark.measure { klass.refresh }
    end
  end
end
