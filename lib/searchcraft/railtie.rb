require "rails/railtie"

module SearchCraft
  class Railtie < Rails::Railtie
    initializer "searchcraft.reloader_hook" do
      ActiveSupport::Reloader.to_prepare do
        SearchCraft::Builder.rebuild_any_if_changed!
      rescue => e
        # Probably missing tables before migrations run
        puts "Preparing SearchCraft: #{e.message}"
      end
    end
  end
end
