module SearchCraft
  class Configuration
    attr_accessor :disable_autorebuild
    attr_accessor :disable_annotate
    attr_writer :debug
    attr_reader :explicit_builder_classes
    attr_accessor :explicit_builder_class_names
    attr_accessor :explicit_model_class_names
    attr_reader :view_hash_store_table_name

    def autorebuild?
      !disable_autorebuild
    end

    def debug
      @debug || ENV["SEARCHCRAFT_DEBUG"] == "true"
    end

    # If you need to explicitly list the builder + model classes you want to use,
    # then set this to a hash of builder class names => model class names.
    # {
    #   "Search::Builder::ContentArticleSearchBuilder" => "Search::ContentArticleSearch",
    #   "Search::Builder::ContentPageSearchBuilder" => "Search::ContentPageSearch"
    # }
    def explicit_builder_classes=(builders_and_models)
      @explicit_builder_classes = builders_and_models
      @explicit_builder_class_names = builders_and_models.keys
      @explicit_model_class_names = builders_and_models.values
    end

    def view_hash_store_table_name=(table_name)
      @view_hash_store_table_name = table_name
      SearchCraft::ViewHashStore.table_name = table_name
    end
  end
end
