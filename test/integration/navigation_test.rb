require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  setup do
    Rails::Assessment.registry.reset

    Rails::Assessment.define "layout-check" do
      title "Layout Check"
      hook "Ensure engine layout renders."

      question "Ready?" do
        option "Yes", tag: :yes
      end
    end
  end

  teardown do
    Rails::Assessment.registry.reset
  end

  test "assessment show page renders engine layout with theme stylesheet" do
    get "/rails-assessment/layout-check"
    assert_response :success

    assert_select "body.rails-assessment-body"
    assert_includes response.body, "rails/assessment/theme"
  end
end
