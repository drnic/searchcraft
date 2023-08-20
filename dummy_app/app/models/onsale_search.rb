# == Schema Information
#
# Table name: onsale_searches
#
#  base_price       :integer
#  currency         :string
#  discount_percent :integer
#  price            :integer
#  product_name     :string
#  sale_price       :integer
#  product_id       :bigint
#
class OnsaleSearch < ActiveRecord::Base
  include SearchCraft::Model

  belongs_to :product, foreign_key: :product_id, primary_key: :id
end
