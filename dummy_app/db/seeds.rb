num_products = ENV.fetch('NUM_PRODUCTS', 50).to_i
num_categories = ENV.fetch('NUM_CATEGORIES', 10).to_i

ProductCategory.destroy_all
Product.destroy_all
Category.destroy_all

puts "Creating #{num_products} products..."
num_products.times do |i|
  Product.create!(
    name: Faker::Commerce.product_name,
    active: true
  )
end

puts "Creating #{num_categories} categories..."
num_categories.times do |i|
  Category.create!(
    name: Faker::Commerce.department,
    active: true
  )
end

puts "Creating product categories..."
Product.all.each do |product|
  join_categories = Category.limit(rand(1..num_categories))
  join_categories.each do |category|
    ProductCategory.create!(
      product: product,
      category: category
    )
  end
end
puts "Created #{ProductCategory.count} product categories."
