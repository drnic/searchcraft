# == Schema Information
#
# Table name: product_searches
#
#  average_review_for_latest :decimal(, )
#  base_price                :integer
#  currency                  :string
#  customer_reviews_count    :bigint
#  image_url                 :string
#  number                    :integer
#  number_review_for_latest  :bigint
#  price                     :integer
#  product_name              :string
#  reviews_average           :decimal(, )
#  reviews_count             :bigint
#  sale_price                :integer
#  total_review_for_latest   :bigint
#  product_id                :bigint
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
