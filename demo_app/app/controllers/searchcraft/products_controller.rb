class Searchcraft::ProductsController < ApplicationController
  before_action :set_currency

  def index
    # if request path is root_path then redirect to /searchcraft/products
    redirect_to searchcraft_products_path and return if request.path == root_path

    @categories = Category.order(:name).load

    @products = ProductSearch.all

    if (category_id = allowed_params.delete(:category_id))
      if (@category = Category.find_by(id: category_id))
        @products = @products.within_category(@category)
      else
        redirect_to searchcraft_products_path, alert: "Category not found"
        return
      end
    else
      @onsale_products = OnsaleSearch.all.load
    end

    @products.load

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
