namespace :searchcraft do
  desc "Recreates search builders' materialized views if necessary"
  task rebuild: :environment do
    puts "Rebuilding search builders' materialized views if necessary"
    puts Benchmark.measure {
      SearchCraft::Builder.rebuild_any_if_changed!
    }
  end

  desc "Recreates all materialized views' indices"
  task recreate_indexes: :environment do
    puts "Recreating search builders' indices"
    puts Benchmark.measure {
      SearchCraft::Builder.recreate_indexes!
    }
  end

  desc "Force recreate all materialize views, including indexes and sequences"
  task force_recreate: :environment do
    puts "Force recreateing search builders' materialized views"
    puts Benchmark.measure {
      SearchCraft::Builder.rebuild_all!
    }
  end
end
