class SearchCraft::Builder
  include SearchCraft::Annotate
  include SearchCraft::DependsOn
  include SearchCraft::DumpSchema

  # Subclass must implement view_scope or view_select_sql
  def view_scope
    raise NotImplementedError, "Subclass must implement view_scope or view_select_sql"
  end

  # By default, assumes subclass implements view_scope to return
  # an ActiveRecord::Relation.
  # Alternately, override view_select_sql to return a SQL string.
  def view_select_sql
    view_scope.to_sql
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
    end

    def builders_to_rebuild
      if Object.const_defined?(:Rails) && Rails.application
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

      # Ugh, this doesn't work for StoreConnect
      Rails.configuration.eager_load_paths.each do |load_path|
        Dir.glob("#{load_path}/**/*.rb").each do |file|
          File.readlines(file).each do |line|
            if (match = line.match(/class\s+([\w:]+)\s*<\s*#{potential_superclass_regex}/))
              class_name = match[1]
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
    dependency_changed = (@@dependencies[self.class.name] || []) & builders_changed.map(&:name)
    if dependency_changed.any? || SearchCraft::ViewHashStore.changed?(builder: self)
      if dependency_changed.any?
        warn "Recreating #{view_name} because #{dependency_changed.join(" ")} changed"
      elsif SearchCraft::ViewHashStore.exists?(builder: self)
        warn "Recreating #{view_name} because SQL changed"
      end
      drop_view!
      create_view!
      update_hash_store!
      dump_schema!
      annotate_models!
      true
    else
      false
    end
  end

  def create_view!
    create_sequence!
    ActiveRecord::Base.connection.execute(view_sql)
    create_indexes!
  end

  # Finds and drops all indexes and sequences on view, and then drops view
  def drop_view!
    # drop indexes used by view before being dropped
    indexes = ActiveRecord::Base.connection.execute("SELECT indexname FROM pg_indexes WHERE tablename = '#{view_name}';")
    indexes.each do |index|
      ActiveRecord::Base.connection.execute("DROP INDEX IF EXISTS #{index["indexname"]};")
    end

    ActiveRecord::Base.connection.execute("DROP MATERIALIZED VIEW IF EXISTS #{view_name} CASCADE;")

    ActiveRecord::Base.connection.execute("DROP SEQUENCE IF EXISTS #{view_id_sequence_name};")

    SearchCraft::ViewHashStore.reset!(builder: self)
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
    self.class.name.gsub(/Builder$/, "").tableize.tr("/", "_")
  end

  def create_sequence!
    ActiveRecord::Base.connection.execute("CREATE SEQUENCE #{view_id_sequence_name} CYCLE;")
  end

  def create_indexes!
    view_indexes.each do |index_name, index_options|
      columns = index_options[:columns]
      name = "idx_#{base_sql_name}_#{index_name}"
      options = index_options.except(:columns).merge({name: name})

      ActiveRecord::Base.connection.add_index(view_name, columns, **options)
    end
  end

  def update_hash_store!
    SearchCraft::ViewHashStore.update_for(builder: self)
  end
end
