# == Schema Information
#
# Table name: colors
#
#  id         :bigint           not null, primary key
#  css_class  :string           not null
#  label      :string           not null
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Color < ApplicationRecord
  has_many :product_colors, dependent: :destroy
  has_many :products, through: :product_colors

  scope :sorted, -> { order(position: :asc) }
end
