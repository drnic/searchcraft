class OnsaleSearchBuilder < SearchCraft::Builder
  def view_scope # standard:disable Lint/DuplicateMethods
    Product
      .joins(:product_prices)
      .where(active: true) # only active products
      .where(product_prices: {sale_price: [1..Float::INFINITY]}) # only products on sale
      .order("discount_percent DESC")
      .limit(5)
      .select(
        "products.id AS product_id, " \
        "products.name AS product_name, " \
        "product_prices.base_price AS base_price, " \
        "product_prices.sale_price AS sale_price, " \
        "product_prices.sale_price AS price, " \
        "product_prices.currency AS currency, " \
        "CAST(ROUND((1 - (1.0 * product_prices.sale_price / product_prices.base_price)) * 100) AS integer) AS discount_percent"
      )
  end
end
