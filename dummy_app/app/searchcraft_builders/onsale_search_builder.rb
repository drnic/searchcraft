class OnsaleSearchBuilder < SearchCraft::Builder
  def view_scope
    Product
      .joins(:product_prices)
      .where(active: true) # only active products
      .where(product_prices: {sale_price: [1..Float::INFINITY]}) # only products on sale
      .order("discount_percent DESC")
      .limit(4)
      .select(
        "products.id AS product_id, " \
        "products.name AS product_name, " \
        "products.image_url AS image_url, " \
        "product_prices.base_price AS base_price, " \
        "product_prices.sale_price AS sale_price, " \
        "product_prices.sale_price AS price, " \
        "product_prices.currency AS currency, " \
        "CAST(ROUND((1 - (1.0 * product_prices.sale_price / product_prices.base_price)) * 100) AS integer) AS discount_percent", \
        "(SELECT COUNT(*) FROM product_reviews WHERE product_reviews.product_id = products.id) AS reviews_count", \
        "(SELECT AVG(rating) FROM product_reviews WHERE product_reviews.product_id = products.id) AS reviews_average", \
        # Count reviews by unique customers
        "(SELECT COUNT(DISTINCT product_reviews.customer_id) FROM product_reviews WHERE product_reviews.product_id = products.id) AS customer_reviews_count", \
        # Find the latest review for each customer, and average their rating
        "(SELECT AVG(rating) FROM (SELECT DISTINCT ON (customer_id) rating FROM product_reviews WHERE product_reviews.product_id = products.id ORDER BY customer_id, created_at DESC) AS latest_reviews) AS average_review_for_latest"
      )
  end
end
