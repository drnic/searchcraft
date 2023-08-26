# == Schema Information
#
# Table name: product_prices
#
#  id         :bigint           not null, primary key
#  product_id :bigint           not null
#  base_price :integer          not null
#  sale_price :integer
#  currency   :string           default("AUD"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ProductPrice < ApplicationRecord
  belongs_to :product
end
