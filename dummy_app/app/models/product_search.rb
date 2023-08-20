class ProductSearch < ActiveRecord::Base
  include SearchCraft::Model

  belongs_to :product, foreign_key: :product_id, primary_key: :id
  belongs_to :category, foreign_key: :category_id, primary_key: :id

  scope :within_category, ->(category) { where(category: category) }
end
