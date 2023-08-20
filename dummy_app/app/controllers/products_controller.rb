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
    @products = @products.within_category(@category)

    @products = @products.load
  end

  def set_currency
    @currency = params[:currency] || "AUD"
  end
end
