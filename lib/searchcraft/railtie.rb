require "rails/railtie"

module SearchCraft
  class Railtie < Rails::Railtie
    initializer "searchcraft.reloader_hook" do
      ActiveSupport::Reloader.to_prepare do
        puts "Running: SearchCraft::Builder.rebuild_any_if_changed!"
        SearchCraft::Builder.rebuild_any_if_changed!
      rescue => e
        # Probably missing tables before migrations run
        puts "Preparing SearchCraft: #{e.message}"
        puts e.backtrace
      end
    end
  end
end
