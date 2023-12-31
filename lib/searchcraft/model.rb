require "scenic"

module SearchCraft::Model
  # Maintain a list of classes that include this module
  @included_classes = []

  # Class method to add a class to the list of included classes
  def self.included(base)
    if base.is_a?(Class)
      base.extend ClassMethods

      if base.is_a?(ClassMethods) && base.respond_to?(:table_name=)
        base.table_name = base.name.to_s.tableize.tr("/", "_")

        @included_classes << base unless @included_classes.include?(base)
      end
    end
    super
  end

  # Runs .refresh! on all classes that include SearchCraft::Model
  def self.refresh_all!
    included_classes.each do |klass|
      warn "Refreshing materialized view #{klass.table_name}..." unless Rails.env.test?
      if klass.is_a?(ClassMethods)
        klass.refresh!
      end
    end
  end

  def self.included_classes
    @included_classes | if SearchCraft.config.explicit_model_class_names
      SearchCraft.config.explicit_model_class_names.map(&:constantize)
    else
      []
    end
  end

  module ClassMethods
    def refresh!
      Scenic.database.refresh_materialized_view(table_name, concurrently: @refresh_concurrently, cascade: false)
    end

    def refresh_concurrently=(value)
      @refresh_concurrently = value
    end
  end

  def read_only?
    true
  end
end
