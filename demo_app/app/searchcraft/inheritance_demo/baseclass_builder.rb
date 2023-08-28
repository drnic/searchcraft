class InheritanceDemo::BaseclassBuilder < SearchCraft::Builder
  def view_select_sql
    # name column is 'Product #1', 'Product #2', etc.
    "SELECT 'Product #' || generate_series(1, 3) AS name;"
  end
end
