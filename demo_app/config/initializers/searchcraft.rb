SearchCraft.configure do |config|
  # Set debug=true to show progress + errors
  config.debug = ENV["SEARCHCRAFT_DEBUG"] == "true"

  config.disable_autorebuild = Rails.env.production?

  # If autodiscovery does not work for you, you can explicitly list the
  # builder classes you want to use.
  #
  # config.explicit_builder_class_names = [
  #   "InheritanceDemo::BaseclassBuilder",
  #   "InheritanceDemo::SubclassBuilder"
  # ]
end
