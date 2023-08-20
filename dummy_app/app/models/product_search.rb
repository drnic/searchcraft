# == Schema Information
#
# Table name: product_searches
#
#  category_name :string
#  product_name  :string
#  category_id   :bigint
#  product_id    :bigint
#
# Indexes
#
#  idx_product_searches_category_id  (category_id)
#
class ProductSearch < ActiveRecord::Base
  include SearchCraft::Model

  belongs_to :product, foreign_key: :product_id, primary_key: :id
  belongs_to :category, foreign_key: :category_id, primary_key: :id

  scope :within_category, ->(category) { where(category: category) }

  # Returns name, or if inactive, returns "name (inactive)"
  def to_s
    product_name
  end
end
