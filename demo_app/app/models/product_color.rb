# == Schema Information
#
# Table name: product_colors
#
#  id         :bigint           not null, primary key
#  product_id :bigint           not null
#  color_id   :bigint           not null
#  active     :boolean          default(TRUE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ProductColor < ApplicationRecord
  belongs_to :product
  belongs_to :color
end
