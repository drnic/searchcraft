require "test_helper"

class Slow::ProductsControllerTest < ActionDispatch::IntegrationTest
  test "slow raw scopes" do
    get root_url
    assert_response :success

    product1 = products(:one)
    product2 = products(:two)
    assert_select "#products li[data-product-id=#{product1.id}]"
    assert_select "#products li[data-product-id=#{product2.id}]"
  end

  test "raw scopes filter by category" do
    get slow_products_url(category_id: categories(:one).id)
    assert_response :success

    product1 = products(:one)
    product2 = products(:two)
    assert_select "#products li[data-product-id=#{product1.id}]"
    assert_select "#products li[data-product-id=#{product2.id}]", count: 0
  end
end
