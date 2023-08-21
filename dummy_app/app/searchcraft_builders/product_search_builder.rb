class ProductSearchBuilder < SearchCraft::Builder
  def view_scope # standard:disable Lint/DuplicateMethods
    Product
      .joins(:categories, :product_prices)
      .where(active: true) # only active products
      .where(categories: {active: true}) # only active categories
      .order(:product_name)
      .select(
        "products.id AS product_id, " \
        "products.name AS product_name, " \
        "categories.id AS category_id, " \
        "categories.name AS category_name", \
        "product_prices.base_price AS base_price, " \
        "product_prices.sale_price AS sale_price, " \
        "product_prices.currency AS currency, " \
        "COALESCE(product_prices.sale_price, product_prices.base_price) AS price"
      )
  end

  def view_indexes
    {
      # index_name: {columns: ["column1", "column2"], unique: false}
      category_id: {columns: ["category_id"]}
    }
  end
end
