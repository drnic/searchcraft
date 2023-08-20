class ProductsController < ApplicationController
  before_action :set_currency

  def index
    @categories = Category.order(:name).load

    if (@using_searchcraft = params.delete(:searchcraft) == "true")
      return index_by_searchcraft
    end

    @products = Product.where(active: true).order(:name)

    if (category_id = params.delete(:category_id))
      @category = Category.find(category_id)
      @products = @products.within_category(@category)
    end

    @products = @products.load

    # Find the products on sale (ProductPrice.sale_price is not null)
    # and with the biggest base price to sale price discount %
    @onsale_products = Product.joins(:product_prices)
      .where(active: true) # only active products
      .where(product_prices: {sale_price: [1..Float::INFINITY]}) # only products on sale
      .where(product_prices: {currency: @currency})
      .order("discount_percent DESC")
      .limit(5)
      .select(
        "products.*, " \
        "CAST(ROUND((1 - (1.0 * product_prices.sale_price / product_prices.base_price)) * 100) AS integer) AS discount_percent"
      )
      .load
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  private

  def index_by_searchcraft
    @categories = Category.order(:name).load

    @products = ProductSearch.all

    unless (category_id = params.delete(:category_id))
      # get first category and redirect to filter by it
      category_id = @categories.first.id
      return redirect_to root_url(searchcraft: true, category_id: category_id)
    end

    @category = Category.find(category_id)
    @products = ProductSearch.within_category(@category).load
    @onsale_products = OnsaleSearch.all.load
  end

  def set_currency
    @currency = params[:currency] || "AUD"
  end
end
