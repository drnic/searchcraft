class CreateProductPrices < ActiveRecord::Migration[7.0]
  def change
    create_table :product_prices do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :base_price, null: false
      t.integer :sale_price
      t.string :currency, null: false, default: "AUD"

      t.timestamps
    end
  end
end
