# == Schema Information
#
# Table name: product_searches
#
#  average_review_for_latest :decimal(, )
#  base_price                :integer
#  category_name             :string
#  currency                  :string
#  customer_reviews_count    :bigint
#  number_review_for_latest  :bigint
#  price                     :integer
#  product_name              :string
#  reviews_average           :decimal(, )
#  reviews_count             :bigint
#  sale_price                :integer
#  total_review_for_latest   :bigint
#  category_id               :bigint
#  product_id                :bigint
#
# Indexes
#
#  idx_product_searches_category_id  (category_id)
#
class ProductSearch < ActiveRecord::Base
  include SearchCraft::Model

  belongs_to :product, foreign_key: :product_id, primary_key: :id

  scope :within_category, ->(category) { joins(product: :product_categories).where(products: {product_categories: {category_id: category.id}}) }

  # Returns name, or if inactive, returns "name (inactive)"
  def to_s
    product_name
  end
end
