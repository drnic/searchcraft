# == Schema Information
#
# Table name: product_prices
#
#  id         :bigint           not null, primary key
#  base_price :integer          not null
#  currency   :string           default("AUD"), not null
#  sale_price :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :bigint           not null
#
# Indexes
#
#  index_product_prices_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#
class ProductPrice < ApplicationRecord
  belongs_to :product
end
