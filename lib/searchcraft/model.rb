require "scenic"

module SearchCraft::Model
  extend ActiveSupport::Concern

  included do
    def read_only?
      true
    end
    self.table_name = name.tableize.tr("/", "_")
  end

  class_methods do
    def refresh!
      Scenic.database.refresh_materialized_view(table_name, concurrently: @refresh_concurrently, cascade: false)
    end

    def refresh_concurrently=(value)
      @refresh_concurrently = value
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

    def included_classes
      if SearchCraft.config.explicit_model_class_names
        return SearchCraft.config.explicit_model_class_names.map(&:constantize)
      end
      @included_classes
    end

    # Runs .refresh! on all classes that include SearchCraft::Model
    # TODO: eager load all classes that include SearchCraft::Model;
    # perhaps via Builder eager loading?
    def refresh_all!
      included_classes.each do |klass|
        warn "Refreshing materialized view #{klass.table_name}..." unless Rails.env.test?
        klass.refresh!
      end
    end
  end
end
