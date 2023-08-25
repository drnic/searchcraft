class CreateProductReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :product_reviews do |t|
      t.references :product, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.integer :rating
      t.text :comment

      t.timestamps
    end
  end
end
