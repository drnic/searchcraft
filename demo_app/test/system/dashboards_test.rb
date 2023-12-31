require "application_system_test_case"

class DashboardsTest < ApplicationSystemTestCase
  test "visiting the dashboards" do
    visit slow_products_url

    assert_selector "h2", text: "Biggest Discounts"
    assert_selector "h2", text: "Products"
    assert_selector "h2", text: "ProductSearches", count: 0

    within "header nav" do
      click_on "SearchCraft"
    end

    assert_selector "h2", text: "Biggest Discounts"
    assert_selector "h2", text: "Products", count: 0
    assert_selector "h2", text: "ProductSearches"
  end
end
