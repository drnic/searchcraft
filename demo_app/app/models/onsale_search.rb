# == Schema Information
#
# Table name: onsale_searches
#
#  average_review_for_latest :decimal(, )
#  base_price                :integer
#  currency                  :string
#  customer_reviews_count    :bigint
#  discount_percent          :integer
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
class OnsaleSearch < ActiveRecord::Base
  include SearchCraft::Model

  belongs_to :product, foreign_key: :product_id, primary_key: :id
end
