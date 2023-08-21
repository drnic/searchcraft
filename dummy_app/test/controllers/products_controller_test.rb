require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "slow raw scopes" do
    get root_url
    assert_response :success

    product1 = products(:one)
    product2 = products(:two)
    assert_select "li#product_#{product1.id}"
    assert_select "li#product_#{product2.id}"
  end

  test "raw scopes filter by category" do
    get root_url(category_id: categories(:one).id)
    assert_response :success

    product1 = products(:one)
    product2 = products(:two)
    assert_select "li#product_#{product1.id}"
    assert_select "li#product_#{product2.id}", count: 0
  end

  # NOTE: the ProductSearch table is created in the test_helper.rb file
  test "searchcraft all" do
    get root_url(searchcraft: true)
    assert_redirected_to root_url(searchcraft: true, category_id: categories(:one).id)
  end

  test "searchcraft filter by category" do
    get root_url(searchcraft: true, category_id: categories(:one).id)
    assert_response :success

    product1 = products(:one)
    product2 = products(:two)
    puts response.body
    assert_select "li#product_#{product1.id}"
    assert_select "li#product_#{product2.id}", count: 0
  end
end
