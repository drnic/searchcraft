num_products = ENV.fetch('NUM_PRODUCTS', 50).to_i

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

# Products' name ends with their category, e.g. Awesome Paper Knife -> Knife
category_names = Product.pluck(:name).map { |name| name.split.last }.uniq

puts "Creating #{category_names.count} categories..."
category_names.each do |name|
  Category.create!(
    name: name,
    active: true
  )
end

puts "Creating product categories..."
Product.all.each do |product|
  join_categories = Category.limit(rand(1..category_names.count))
  join_categories.each do |category|
    ProductCategory.create!(
      product: product,
      category: category
    )
  end
end
puts "Created #{ProductCategory.count} product categories."
