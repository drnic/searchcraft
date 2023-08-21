require "rails/railtie"

module SearchCraft
  class Railtie < Rails::Railtie
    initializer "searchcraft.reloader_hook" do
      ActiveSupport::Reloader.to_prepare do
        SearchCraft::Builder.rebuild_any_if_changed!
      end
    end
  end
end
