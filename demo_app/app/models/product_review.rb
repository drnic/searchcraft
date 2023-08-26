# == Schema Information
#
# Table name: product_reviews
#
#  id          :bigint           not null, primary key
#  product_id  :bigint           not null
#  customer_id :bigint           not null
#  rating      :integer
#  comment     :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
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
