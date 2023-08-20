require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "slow raw scopes" do
    get root_url
    assert_response :success
  end

  test "raw scopes filter by category" do
    get root_url(category_id: categories(:one).id)
    assert_response :success
  end

  test "searchcraft all" do
    get root_url(searchcraft: true)
    assert_response :success
  end

  test "searchcraft filter by category" do
    get root_url(searchcraft: true, category_id: categories(:one).id)
    assert_response :success
  end
end
