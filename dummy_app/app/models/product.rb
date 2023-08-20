# == Schema Information
#
# Table name: products
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE)
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Product < ApplicationRecord
  has_many :product_categories, dependent: :destroy
  has_many :categories, through: :product_categories

  # Returns name, or if inactive, returns "name (inactive)"
  def to_s
    if active?
      name
    else
      "#{name} (inactive)"
    end
  end
end
