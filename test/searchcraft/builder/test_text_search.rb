# frozen_string_literal: true

module TextSearch
  # A materialized view with a name column
  class ProductBuilder < SearchCraft::Builder
    def view_select_sql
      <<~SQL
        SELECT
          1 AS id,
          'apples' AS name,
          'red' AS description
        UNION
        ALL
        SELECT
          2 AS id,
          'apple pie' AS name,
          'delicious' AS description
        UNION
        ALL
        SELECT
          3 AS id,
          'apple tea' AS name,
          'liquid' AS description
        UNION
        ALL
        SELECT
          4 AS id,
          'bananas' AS name,
          'yellow' AS description
      SQL
    end
  end

  class ProductTextSearchBuilder < SearchCraft::Builder
    depends_on "TextSearch::ProductBuilder"

    def view_scope
      product_table = TextSearch::Product.arel_table
      search_document = [
        setweight_arel(product_table[:name], weight: "A"),
        setweight_arel(product_table[:description], weight: "B")
      ].reduce do |accum, component|
        Arel::Nodes::Concat.new(accum, component)
      end.as("search_document")

      TextSearch::Product.select(
        product_table[:id].as("product_id"),
        search_document
      )
    end
  end

  class Product < ActiveRecord::Base
    include SearchCraft::Model
    self.primary_key = :id

    has_one :product_text_search, foreign_key: :product_id
  end

  class ProductTextSearch < ActiveRecord::Base
    include SearchCraft::Model

    belongs_to :product, foreign_key: :product_id

    # TODO: Can these be moved into ::Model or similar module?
    class << self
      def by_keywords(keywords)
        where("search_document @@ websearch_to_tsquery('english', ?)", keywords)
      end

      def add_ranking(keywords)
        select(column_names, tsrank_function(keywords).as("ranking"))
      end

      def order_by_ranking
        order("ranking DESC")
      end

      def tsrank_function(keywords, search_column: :search_document, search_function: "websearch_to_tsquery")
        Arel::Nodes::NamedFunction.new(
          "ts_rank",
          [
            arel_table[search_column],
            Arel::Nodes::NamedFunction.new(search_function, [
              Arel::Nodes.build_quoted("english"),
              Arel::Nodes.build_quoted(keywords)
            ])
          ]
        )
      end
    end
  end
end

describe SearchCraft::Builder do
  before do
    # Connection to PostgreSQL server
    database_url = ENV.fetch("DATABASE_URL", "postgres://localhost:5432")
    ActiveRecord::Base.establish_connection(database_url)

    # Database name
    database_name = "searchcraft_gem_test_text_search"

    begin
      ActiveRecord::Base.connection.drop_database(database_name)
      puts "Dropped existing database '#{database_name}'"
    rescue ActiveRecord::NoDatabaseError
    end

    at_exit do
      ActiveRecord::Base.connection_pool.disconnect!
      ActiveRecord::Base.establish_connection(database_url)
      ActiveRecord::Base.connection.drop_database(database_name)
      puts "\nExiting... Dropped database '#{database_name}'"
    end

    # Create the database
    ActiveRecord::Base.connection.create_database(database_name)
    puts "Created new database '#{database_name}'"
    ActiveRecord::Base.establish_connection("#{database_url}/#{database_name}")

    SearchCraft::Builder.rebuild_any_if_changed!
    TextSearch::Product.reset_column_information
    TextSearch::ProductTextSearch.reset_column_information
  end

  it "creates tsvector column" do
    # pp TextSearch::Product.all
    # [#<TextSearch::Product id: 1, name: "apples", description: "red">,
    #  #<TextSearch::Product id: 2, name: "apple pie", description: "delicious">,
    #  #<TextSearch::Product id: 3, name: "apple tea", description: "liquid">,
    #  #<TextSearch::Product id: 4, name: "bananas", description: "yellow">]
    assert_equal(TextSearch::Product.pluck(:name), ["apples", "apple pie", "apple tea", "bananas"])
    # pp TextSearch::ProductTextSearch.all
    # [#<TextSearch::ProductTextSearch product_id: 1, search_document: "'appl':1A 'red':2B">,
    #  #<TextSearch::ProductTextSearch product_id: 2, search_document: "'appl':1A 'delici':3B 'pie':2A">,
    #  #<TextSearch::ProductTextSearch product_id: 3, search_document: "'appl':1A 'liquid':3B 'tea':2A">,
    #  #<TextSearch::ProductTextSearch product_id: 4, search_document: "'banana':1A 'yellow':2B">]
    assert_equal(TextSearch::ProductTextSearch.pluck(:search_document),
      ["'appl':1A 'red':2B",
        "'appl':1A 'delici':3B 'pie':2A",
        "'appl':1A 'liquid':3B 'tea':2A",
        "'banana':1A 'yellow':2B"])

    # by_keywords(keywords) above performs a filter, but not a sort
    # Finds the 3 "apple" products
    results = TextSearch::ProductTextSearch.by_keywords("apple")

    product_results = TextSearch::Product.joins(:product_text_search).merge(results)
    assert_equal(product_results.pluck(:name), ["apples", "apple pie", "apple tea"])

    # Finds {name: "apple pie", description: "delicious"}
    results = TextSearch::ProductTextSearch.by_keywords("delicious")

    product_results = TextSearch::Product.joins(:product_text_search).merge(results)
    assert_equal(product_results.pluck(:name), ["apple pie"])

    #
    # Ordering by ranking
    #
    results = TextSearch::ProductTextSearch.by_keywords("apple").add_ranking("apple").order_by_ranking
    # SELECT
    #   "text_search_product_text_searches"."product_id",
    #   "text_search_product_text_searches"."search_document",
    #   ts_rank(
    #     "text_search_product_text_searches"."search_document",
    #     websearch_to_tsquery('english', 'apple')
    #   ) AS ranking
    # FROM
    #   "text_search_product_text_searches"
    # WHERE
    #   (search_document @@ websearch_to_tsquery('english', 'apple'))
    # ORDER BY
    #   ranking DESC
    product_results = results.includes(:product).map(&:product)
    assert_equal(product_results.pluck(:name), ["apples", "apple pie", "apple tea"])
  end
end
