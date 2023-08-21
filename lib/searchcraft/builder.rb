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
