class SearchCraft::Builder
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

      # If tests, and after rails db:schema:load, the ViewHashStore table is empty.
      # So just drop any views created from the schema.rb and we'll recreate them.
      unless SearchCraft::ViewHashStore.any?
        builders_to_rebuild.each { |builder| builder.new.drop_view! }
      end
      builders_to_rebuild.each { |builder| builder.new.recreate_view_if_changed! }
    end

    def builders_to_rebuild
      @builders_to_rebuild ||= if Object.const_defined?(:Rails) && Rails.application
        find_subclasses_via_rails_eager_load_paths.map(&:constantize)
      else
        subclasses
      end
    end

    def find_subclasses_via_rails_eager_load_paths
      @subclass_names = []

      Rails.configuration.eager_load_paths.each do |load_path|
        Dir.glob("#{load_path}/**/*.rb").each do |file|
          # TODO: namespaced classes - might need to load the file, and see what was created?
          # Or assume the class name by its file path?
          File.readlines(file).each do |line|
            if (match = line.match(/class\s+(\w+)\s*<\s*SearchCraft::Builder/))
              class_name = match[1]
              @subclass_names << class_name
            end
          end
        end
      end

      @subclass_names
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
  def recreate_view_if_changed!
    if SearchCraft::ViewHashStore.changed?(builder: self)
      warn "Recreating #{view_name} because SQL changed" if SearchCraft::ViewHashStore.exists?(builder: self)
      drop_view!
      create_view!
      # dump_schema!
      SearchCraft::ViewHashStore.update_for(builder: self)
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
    self.class.name.gsub(/Builder$/, "").demodulize.underscore.pluralize
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
end
