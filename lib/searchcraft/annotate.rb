module SearchCraft::Annotate
  # If using annotate gem, then automatically annotate models after rebuilding views
  # TODO: I'm suspicious this is not working for dependent Builders, e.g. demo_app's OnsaleSearchBuilder
  def annotate_models!
    return if SearchCraft.config.disable_annotate
    return unless Rails.env.development?
    return unless Object.const_defined?(:Annotate)

    options = {
      is_rake: true,
      position: "before",
      additional_file_patterns: [],
      model_dir: "app/models",
      root_dir: Rails.root.to_s,
      require: [],
      exclude_controllers: true,
      exclude_helpers: true,
      hide_limit_column_types: "",
      hide_default_column_types: "",
      ignore_unknown_models: true,
      show_indexes: true
    }
    capture_stdout do
      AnnotateModels.do_annotations(options)
    end
  rescue PG::UndefinedTable
  rescue => e
    puts "Error annotating models: #{e.message}"
    pp e.backtrace
  end

  def capture_stdout(&block)
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    if SearchCraft.debug?
      puts $stdout.string
    end
  ensure
    $stdout = old_stdout
  end
end
