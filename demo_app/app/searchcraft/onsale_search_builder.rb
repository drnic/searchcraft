class OnsaleSearchBuilder < SearchCraft::Builder
  depends_on "ProductSearchBuilder"

  def view_scope
    product_search_table = ProductSearch.arel_table
    ProductSearch
      .where(sale_price: [1..Float::INFINITY]) # only products on sale
      .order("discount_percent DESC")
      .limit(4)
      .select(
        product_search_table[Arel.star],
        "CAST(ROUND((1 - (1.0 * #{product_search_table.name}.sale_price / #{product_search_table.name}.base_price)) * 100) AS integer) AS discount_percent"
      )
  end
end
