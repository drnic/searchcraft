require "test_helper"

class Searchcraft::ProductsControllerTest < ActionDispatch::IntegrationTest
  # NOTE: the ProductSearch table is created in the test_helper.rb file
  test "searchcraft all" do
    get searchcraft_products_url
    assert_response :success

    product1 = products(:one)
    product2 = products(:two)
    assert_select "#products li[data-product-id=#{product1.id}]"
    assert_select "#products li[data-product-id=#{product2.id}]"
  end

  test "searchcraft filter by category" do
    get searchcraft_products_url(category_id: categories(:one).id)
    assert_response :success

    product1 = products(:one)
    product2 = products(:two)
    assert_select "#products li[data-product-id=#{product1.id}]"
    assert_select "#products li[data-product-id=#{product2.id}]", count: 0
  end
end
