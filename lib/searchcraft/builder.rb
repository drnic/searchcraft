class SearchCraft::Builder
  # By default, assumes subclass implements view_scope to return
  # an ActiveRecord::Relation.
  # Alternately, override view_select_sql to return a SQL string.
  def view_select_sql
    view_scope.to_sql
  end

  def view_sql
    # remove trailing ; from view_sql
    inner_sql = view_select_sql.gsub(/;\s*$/, "")
    "CREATE MATERIALIZED VIEW #{view_name} AS (#{inner_sql}) WITH DATA;"
  end

  # After materialized view created, what indexes should be added?
  def view_indexes
    {}
  end

  def view_sql_hash
    Digest::SHA256.hexdigest(view_sql)
  end

  def create_view!
    create_sequence!
    ActiveRecord::Base.connection.execute(view_sql)
    create_indexes!
  end

  protected

  # Pluralized table name of class
  def view_name
    base_sql_name
  end

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
