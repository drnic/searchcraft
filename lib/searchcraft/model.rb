require "scenic"

module SearchCraft::Model
  extend ActiveSupport::Concern

  included do
    def read_only?
      true
    end
  end

  class_methods do
    def refresh!
      Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
    end
  end
end
