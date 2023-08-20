class ProductsController < ApplicationController
  def index
    return index_by_searchcraft if params.has_key?(:searchcraft)

    @products = Product.where(active: true).order(:name)

    if (category_id = params.delete(:category_id))
      category = Category.find(category_id)
      @products = @products.within_category(category)
    end

    @products = @products.load

    @categories = Category.order(:name).load
  end

  def index_by_searchcraft
    @products = ProductSearch.all

    if (category_id = params.delete(:category_id))
      category = Category.find(category_id)
      @products = @products.within_category(category)
    end

    @products = @products.load

    @categories = Category.order(:name).load
  end
end
