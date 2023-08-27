class Searchcraft::ProductsController < ApplicationController
  before_action :set_currency

  def index
    @categories = Category.order(:name).load

    @products = ProductSearch.all

    if (category_id = allowed_params.delete(:category_id))
      if (@category = Category.find_by(id: category_id))
        @products = @products.within_category(@category)
      else
        redirect_to root_url(searchcraft: true)
        return
      end
    end

    @products.load
    @onsale_products = OnsaleSearch.all.load

    @url_params = {}
    @url_params[:category_id] = @category.id if @category
  end

  private

  def allowed_params
    params.permit(:category_id)
  end

  def set_currency
    @currency = params[:currency] || "AUD"
  end
end
