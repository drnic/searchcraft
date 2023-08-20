class ProductsController < ApplicationController
  before_action :set_currency

  def index
    if (@using_searchcraft = params.delete(:searchcraft) == "true")
      return index_by_searchcraft
    end

    @products = Product.where(active: true).order(:name)

    if (category_id = params.delete(:category_id))
      @category = Category.find(category_id)
      @products = @products.within_category(@category)
    end

    @products = @products.load

    @categories = Category.order(:name).load
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  private

  def index_by_searchcraft
    @products = ProductSearch.all

    if (category_id = params.delete(:category_id))
      @category = Category.find(category_id)
      @products = @products.within_category(@category)
    end

    @products = @products.load

    @categories = Category.order(:name).load
  end

  def set_currency
    @currency = params[:currency] || "AUD"
  end
end
