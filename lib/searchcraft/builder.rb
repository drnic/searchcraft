class SearchCraft::Builder
  extend SearchCraft::Annotate
  include SearchCraft::DependsOn
  extend SearchCraft::DependsOn::ClassMethods
  include SearchCraft::DumpSchema

  # Subclass must implement view_scope or view_select_sql
  def view_scope
    raise NotImplementedError, "Subclass must implement view_scope or view_select_sql"
  end

  # By default, assumes subclass implements view_scope to return
  # an ActiveRecord::Relation.
  # Alternately, override view_select_sql to return a SQL string.
  def view_select_sql
    @_view_select_sql ||= view_scope.to_sql
  end

  # Override if a Builder SQL has dependencies, such as extensions or text search config
  # that are required first.
  def dependencies_ready?
    true
  end

  class << self
    # Iterate through subclasses, and invoke recreate_view_if_changed!
    def rebuild_any_if_changed!
      SearchCraft::ViewHashStore.setup_table_if_needed!

      sorted_builders = sort_builders_by_dependency

      # If tests, and after rails db:schema:load, the ViewHashStore table is empty.
      # So just drop any views created from the schema.rb and we'll recreate them.

      unless SearchCraft::ViewHashStore.any?
        sorted_builders.each { |builder| builder.new.drop_view! }
      end

      builders_changed = []
      sorted_builders.each do |builder|
        changed = builder.new.recreate_view_if_changed!(builders_changed: builders_changed)
        builders_changed << builder if changed
      end

      annotate_models!
    end

    def rebuild_all!
    end

    def recreate_indexes!
      sorted_builders = sort_builders_by_dependency
      sorted_builders.each { |builder| builder.new.recreate_indexes! }
    end

    def builders_to_rebuild
      if SearchCraft.config.explicit_builder_class_names
        SearchCraft.config.explicit_builder_class_names.map(&:constantize)
      elsif Object.const_defined?(:Rails) && Rails.application
        find_subclasses_via_rails_eager_load_paths.map(&:constantize)
      else
        subclasses
      end
    end

    # Looks for subclasses of SearchCraft::Builder in Rails eager load paths
    # and then any subclasses of those.
    # Returns an array of class names
    def find_subclasses_via_rails_eager_load_paths(known_subclass_names: [])
      subclass_names = []

      potential_superclass_names = known_subclass_names + ["SearchCraft::Builder"]
      potential_superclass_regex = Regexp.new(potential_superclass_names.join("|"))

      Rails.configuration.eager_load_paths.each do |load_path|
        Dir.glob("#{load_path}/**/*.rb").each do |file|
          File.readlines(file).each do |line|
            if (match = line.match(/class\s+([\w:]+)\s*<\s*#{potential_superclass_regex}/))
              class_name = match[1].to_s
              warn "Found #{class_name} in #{file}" unless known_subclass_names.include?(class_name)
              subclass_names << class_name
            end
          end
        end
      end

      newly_found_subclass_names = subclass_names - known_subclass_names
      if newly_found_subclass_names.any?
        return find_subclasses_via_rails_eager_load_paths(known_subclass_names: subclass_names)
      end

      subclass_names
    end
  end

  # Produces the SQL that will create the materialized view
  def view_sql
    # remove trailing ; from view_sql
    inner_sql = view_select_sql.gsub(/;\s*$/, "")
    "CREATE MATERIALIZED VIEW #{view_name} AS (#{inner_sql}) WITH DATA;"
  end

  # After materialized view created, do you need indexes on its columns?
  def view_indexes
    {}
  end

  # To indicate if view has changed, we store a hash of the SQL used to create it
  # TODO: include the indexes SQL too
  def view_sql_hash
    Digest::SHA256.hexdigest(view_sql)
  end

  # If missing or changed, drop and create view
  # Returns false if no change required
  def recreate_view_if_changed!(builders_changed: [])
    if SearchCraft.debug?
      warn "#{self.class.name}#recreate_view_if_changed!"
      warn "  builders_changed: #{builders_changed.map(&:name).join(", ")}" if builders_changed.any?
    end
    return unless dependencies_ready?

    @@dependencies ||= {}
    dependencies_changed = (@@dependencies[self.class.name] || []) & builders_changed.map(&:name)
    return false unless dependencies_changed.any? ||
      SearchCraft::ViewHashStore.changed?(builder: self)

    if SearchCraft.debug?
      if !SearchCraft::ViewHashStore.exists?(builder: self)
        warn "Creating #{view_name} because it doesn't yet exist"
      elsif dependencies_changed.any?
        warn "Recreating #{view_name} because dependencies changed: #{dependencies_changed.join(" ")}"
      else
        warn "Recreating #{view_name} because SQL changed"
      end
    end

    drop_view!
    create_view!
    update_hash_store!
    dump_schema!

    true
  end

  def create_view!
    create_sequence!
    sql_execute(view_sql)
    create_indexes!
  end

  # Finds and drops all indexes and sequences on view, and then drops view
  def drop_view!
    sql_execute("DROP MATERIALIZED VIEW IF EXISTS #{view_name} CASCADE;")

    sql_execute("DROP SEQUENCE IF EXISTS #{view_id_sequence_name};")

    SearchCraft::ViewHashStore.reset!(builder: self)
  end

  def recreate_indexes!
    drop_indexes!
    create_indexes!
  end

  # Pluralized table name of class
  def view_name
    base_sql_name
  end

  protected

  # CREATE SEQUENCE #{view_id_sequence_name} CYCLE;
  # DROP SEQUENCE #{view_id_sequence_name};
  def view_id_sequence_name
    "#{base_sql_name}_seq"
  end

  # ProductSearchBuilder name becomes product_searches
  def base_sql_name
    self.class.name.to_s.gsub(/Builder$/, "").tableize.tr("/", "_")
  end

  def base_idx_name
    "idx_#{base_sql_name}"
  end

  def create_sequence!
    sql_execute("CREATE SEQUENCE #{view_id_sequence_name} CYCLE;")
  end

  def drop_indexes!
    simple_view_name = view_name.gsub(/^.+\./, "")
    indexes = sql_execute("SELECT indexname FROM pg_indexes WHERE tablename = '#{simple_view_name}';")
    indexes.each do |index|
      warn "DROP INDEX IF EXISTS #{index["indexname"]};" if SearchCraft.debug?
      sql_execute("DROP INDEX IF EXISTS #{index["indexname"]};")
    end
  end

  def create_indexes!
    view_indexes.each do |index_name, index_options|
      columns = index_options[:columns]
      name = "#{base_idx_name}_#{index_name}"
      options = index_options.except(:columns).merge({name: name})

      warn "ActiveRecord::Base.connection.add_index(#{view_name.inspect}, #{columns.inspect}, #{options.inspect})" if SearchCraft.debug?
      ActiveRecord::Base.connection.add_index(view_name, columns, **options)
    end
  end

  def update_hash_store!
    SearchCraft::ViewHashStore.update_for(builder: self)
  end

  def sql_execute(sql)
    warn sql if SearchCraft.debug?
    ActiveRecord::Base.connection.execute(sql)
  end
end
