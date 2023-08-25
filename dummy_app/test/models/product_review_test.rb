# == Schema Information
#
# Table name: product_reviews
#
#  id          :bigint           not null, primary key
#  comment     :text
#  rating      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  customer_id :bigint           not null
#  product_id  :bigint           not null
#
# Indexes
#
#  index_product_reviews_on_customer_id  (customer_id)
#  index_product_reviews_on_product_id   (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#  fk_rails_...  (product_id => products.id)
#
require "test_helper"

class ProductReviewTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
