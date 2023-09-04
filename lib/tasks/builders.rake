namespace :searchcraft do
  desc "Recreates search builders' materialized views if necessary"
  task rebuild: :environment do
    puts "Rebuilding search builders' materialized views if necessary"
    puts Benchmark.measure {
      SearchCraft::Builder.rebuild_any_if_changed!
    }
  end
end
