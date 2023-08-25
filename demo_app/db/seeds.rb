num_products = ENV.fetch("NUM_PRODUCTS", 500).to_i

Color.destroy_all
ProductCategory.destroy_all
Product.destroy_all
Category.destroy_all
Customer.destroy_all

puts "Creating colors..."
Color.create!(label: "Red", css_class: "bg-red-500")
Color.create!(position: 2, label: "Gold", css_class: "bg-yellow-500")
Color.create!(position: 3, label: "Silver", css_class: "bg-gray-500")
Color.create!(position: 4, label: "Metallic Blue", css_class: "bg-blue-500")
Color.create!(position: 5, label: "White", css_class: "bg-slate-500")
colors = Color.all

puts "Creating #{num_products} products..."
num_products.times do |i|
  base_product_name = Faker::Commerce.product_name

  # Use base_product_name last word as the primary category
  primary_category = base_product_name.split.last.downcase
  image_url = "https://loremflickr.com/g/320/320/#{primary_category}?lock=#{i + 1}"

  product = Product.create!(
    name: base_product_name,
    image_url: image_url,
    active: true
  )

  # Add a price between 100 and 10_000
  price = product.product_prices.create!(
    base_price: rand(100..10_000)
  )
  # 30% of the time, give a sale price, which is 10-80% off the base price
  if rand(1..10) <= 3
    price.update!(
      sale_price: price.base_price * (1 - rand(100..800) / 1000.0)
    )
  end

  # Give each product 1-5 colors
  colors.order("RANDOM()").limit(rand(1..5)).each do |color|
    product.product_colors.create!(
      color: color,
      active: true
    )
  end
end

# Split product names into categories
category_names = Product.pluck(:name).map { |name| name.split }.flatten.uniq

puts "Creating #{category_names.count} categories..."
category_names.each do |name|
  Category.create!(
    name: name,
    active: true
  )
end

puts "Creating product categories..."
Product.all.each do |product|
  category_names = product.name.split
  category_names.each do |category_name|
    category = Category.find_by(name: category_name)
    ProductCategory.create!(
      product: product,
      category: category
    )
  end
end
puts "Created #{ProductCategory.count} product categories."

puts "Creating customers..."
Customer.create!(name: "John Doe")
Customer.create!(name: "Jane Doe")
Customer.create!(name: "Bob Smith")
Customer.create!(name: "Jeff Jones")

puts "Creating bad product reviews for a week ago..."
Product.all.each do |product|
  Customer.order("RANDOM()").limit(rand(1..4)).each do |customer|
    product.product_reviews.create!(
      customer: customer,
      rating: rand(1..2),
      comment: Faker::Lorem.paragraph,
      created_at: 7.days.ago
    )
  end
end
puts "Creating good product reviews for today..."
Product.all.each do |product|
  Customer.order("RANDOM()").limit(rand(1..4)).each do |customer|
    product.product_reviews.create!(
      customer: customer,
      rating: rand(4..5),
      comment: Faker::Lorem.paragraph
    )
  end
end

puts "Created #{ProductReview.count} product reviews."
products_with_multiple_reviews_per_customer = Product.joins(:product_reviews).group("products.id", "product_reviews.customer_id").having("count(*) > 1").count.keys
puts "Created #{products_with_multiple_reviews_per_customer.count} products with multiple reviews per customer."
