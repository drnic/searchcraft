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
        "COALESCE(product_prices.sale_price, product_prices.base_price) AS price", \
        "(SELECT COUNT(*) FROM product_reviews WHERE product_reviews.product_id = products.id) AS reviews_count", \
        "(SELECT AVG(rating) FROM product_reviews WHERE product_reviews.product_id = products.id) AS reviews_average", \
        # Count reviews by unique customers
        "(SELECT COUNT(DISTINCT product_reviews.customer_id) FROM product_reviews WHERE product_reviews.product_id = products.id) AS customer_reviews_count", \
        # Find the latest review for each customer, and average their rating
        "(SELECT AVG(latest_reviews.rating) FROM (SELECT DISTINCT ON (customer_id) rating FROM product_reviews WHERE product_reviews.product_id = products.id ORDER BY customer_id, created_at DESC) AS latest_reviews) AS average_review_for_latest", \
        "(SELECT SUM(latest_reviews.rating) FROM (SELECT DISTINCT ON (customer_id) rating FROM product_reviews WHERE product_reviews.product_id = products.id ORDER BY customer_id, created_at DESC) AS latest_reviews) AS total_review_for_latest", \
        "(SELECT COUNT(latest_reviews.rating) FROM (SELECT DISTINCT ON (customer_id) rating FROM product_reviews WHERE product_reviews.product_id = products.id ORDER BY customer_id, created_at DESC) AS latest_reviews) AS number_review_for_latest"
      )
  end

  def view_indexes
    {
      # index_name: {columns: ["column1", "column2"], unique: false}
      category_id: {columns: ["category_id"]}
    }
  end
end
