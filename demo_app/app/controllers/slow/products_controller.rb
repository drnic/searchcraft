class Slow::ProductsController < ApplicationController
  before_action :set_currency

  def index
    @categories = Category.order(:name).load

    @products = Product.where(active: true).order(:name)

    if (category_id = allowed_params.delete(:category_id))
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
      .limit(4)
      .select(
        "products.*, " \
        "CAST(ROUND((1 - (1.0 * product_prices.sale_price / product_prices.base_price)) * 100) AS integer) AS discount_percent"
      )
      .load

    @url_params = {}
    @url_params[:category_id] = @category.id if @category
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  private

  def allowed_params
    params.permit(:category_id)
  end

  def set_currency
    @currency = params[:currency] || "AUD"
  end
end
