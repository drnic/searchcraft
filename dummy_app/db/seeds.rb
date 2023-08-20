num_products = ENV.fetch("NUM_PRODUCTS", 500).to_i

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
