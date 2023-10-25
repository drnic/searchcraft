module SearchCraft::TextSearch
  # setweight(to_tsvector('english', COALESCE(display_name, name, ''), 'C')
  def setweight_arel(*columns, weight: "C", language: "english")
    Arel::Nodes::NamedFunction.new(
      "setweight",
      [
        to_tsvector_arel(*columns, language: language),
        Arel.sql("'#{weight}'")
      ]
    )
  end

  # to_tsvector('english', COALESCE(display_name, name, ''))
  def to_tsvector_arel(*columns, language: "english")
    Arel::Nodes::NamedFunction.new(
      "to_tsvector",
      [
        Arel.sql("'#{language}'"),
        coalesce([
          *columns,
          Arel::Nodes::SqlLiteral.new("''")
        ])
      ]
    )
  end

  # COALESCE(display_name, name)
  def coalesce(columns)
    Arel::Nodes::NamedFunction.new "COALESCE", columns
  end
end
