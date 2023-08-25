# == Schema Information
#
# Table name: products
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE)
#  image_url  :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Product < ApplicationRecord
  has_many :product_reviews, dependent: :destroy
  has_many :product_categories, dependent: :destroy
  has_many :categories, through: :product_categories
  has_many :product_prices, dependent: :destroy
  has_many :product_colors, dependent: :destroy
  has_many :active_product_colors, -> { where(active: true) }, dependent: :destroy, class_name: "ProductColor"
  has_many :colors, through: :product_colors
  has_many :active_colors, through: :active_product_colors, class_name: "Color", source: :color

  scope :within_category, ->(category) { joins(product_categories: :category).where(categories: {id: category.id, active: true}) }

  # Returns name, or if inactive, returns "name (inactive)"
  def to_s
    if active?
      name
    else
      "#{name} (inactive)"
    end
  end
end
