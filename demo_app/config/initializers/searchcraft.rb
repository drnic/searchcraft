ActiveSupport::Reloader.to_prepare do
  SearchCraft.configure do |config|
    # If autodiscovery does not work for you, you can explicitly list the
    # builder classes you want to use.
    #
    # config.explicit_builder_class_names = [
    #   "InheritanceDemo::BaseclassBuilder",
    #   "InheritanceDemo::SubclassBuilder"
    # ]
  end
end
