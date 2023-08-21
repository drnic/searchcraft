# == Schema Information
#
# Table name: product_colors
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  color_id   :bigint           not null
#  product_id :bigint           not null
#
# Indexes
#
#  index_product_colors_on_color_id    (color_id)
#  index_product_colors_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (color_id => colors.id)
#  fk_rails_...  (product_id => products.id)
#
require "test_helper"

class ProductColorTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
