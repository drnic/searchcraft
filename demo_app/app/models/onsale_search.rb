# == Schema Information
#
# Table name: onsale_searches
#
#  number                    :integer
#  product_id                :bigint
#  product_name              :string
#  image_url                 :string
#  base_price                :integer
#  sale_price                :integer
#  currency                  :string
#  price                     :integer
#  reviews_count             :bigint
#  reviews_average           :decimal(, )
#  customer_reviews_count    :bigint
#  average_review_for_latest :decimal(, )
#  total_review_for_latest   :bigint
#  number_review_for_latest  :bigint
#  discount_percent          :integer
#
class OnsaleSearch < ActiveRecord::Base
  include SearchCraft::Model

  belongs_to :product, foreign_key: :product_id, primary_key: :id
end
