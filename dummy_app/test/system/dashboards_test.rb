require "application_system_test_case"

class DashboardsTest < ApplicationSystemTestCase
  test "visiting the dashboards" do
    visit root_url

    assert_selector "h2", text: "Biggest Discounts"
    assert_selector "h1", text: "Categories"
    assert_selector "h1", text: "Products"
    assert_selector "h1", text: "ProductSearches", count: 0

    click_on "SearchCraft"

    assert_selector "h2", text: "Biggest Discounts"
    assert_selector "h1", text: "Categories"
    assert_selector "h1", text: "Products", count: 0
    assert_selector "h1", text: "ProductSearches"
  end
end
