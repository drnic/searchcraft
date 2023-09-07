require "rails/railtie"

module SearchCraft
  class Railtie < Rails::Railtie
    initializer "searchcraft.reloader_hook" do
      ActiveSupport::Reloader.to_prepare do
        next unless SearchCraft.database_ready?
        next unless SearchCraft.config.autorebuild?

        warn "[#{Rails.env}] running: SearchCraft::Builder.rebuild_any_if_changed!" if SearchCraft.debug?

        SearchCraft::Builder.rebuild_any_if_changed!
      rescue => e
        if SearchCraft.debug?
          puts "Preparing SearchCraft: #{e.message}"
          puts e.backtrace
        end
      end
    end
  end
end
