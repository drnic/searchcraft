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
class ProductReview < ApplicationRecord
  belongs_to :product
  belongs_to :customer

  # Find the latest review for each customer
  # Whilst it returns an ActiveRecord::Relation, it is not chainable; no pluck, average, sum, etc
  scope :latest_per_customer, -> {
    select("DISTINCT ON (customer_id) *")
      .order("customer_id, created_at DESC")
  }

  def self.average_rating_for_latest_review_per_customer
    # latest_per_customer.average(:rating) - skips the scope and averages all records
    latest_reviews_ratings = latest_per_customer.map(&:rating)
    return nil if latest_reviews_ratings.empty?
    latest_reviews_ratings.sum.to_f / latest_reviews_ratings.size
  end
end
