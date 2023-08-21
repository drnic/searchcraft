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

  # Maintain a list of classes that include this module
  @included_classes = []

  class << self
    # Class method to add a class to the list of included classes
    def included(base)
      @included_classes << base
      super
    end

    # Runs .refresh! on all classes that include SearchCraft::Model
    def refresh_all!
      @included_classes.each do |klass|
        warn "Refreshing materialized view #{klass.table_name}..." unless Rails.env.test?
        klass.refresh!
      end
    end
  end
end
