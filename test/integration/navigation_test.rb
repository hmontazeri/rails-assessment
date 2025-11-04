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

  test "assessment show page renders logo when configured" do
    Rails::Assessment.define "logo-check" do
      title "Logo Check"
      hook "Ensure logo renders."
      logo "https://example.com/logo.png"

      question "Ready?" do
        option "Yes", tag: :yes
      end
    end

    get "/rails-assessment/logo-check"
    assert_response :success

    assert_select "section.assessment .assessment-logo img.assessment-logo-image[src='https://example.com/logo.png']"
  end

  test "assessment renders start screen and keeps content inactive when enabled" do
    Rails::Assessment.define "start-screen-check" do
      title "Start Screen Check"
      hook "Ensure start screen renders."
      description "Short intro before the assessment begins."
      estimated_time "2 minutes"
      show_start_screen true

      question "Ready?" do
        option "Yes", tag: :yes
      end
    end

    get "/rails-assessment/start-screen-check"
    assert_response :success

    assert_select "section.assessment[data-assessment-show-start-screen-value='true']"
    assert_select ".assessment-start-screen.is-active[data-assessment-target='startScreen']"
    assert_select ".assessment-start-screen .btn-start", text: "Start Assessment"
    assert_select ".assessment-start-meta .assessment-start-meta-item", text: "2 minutes"
    assert_select ".assessment-start-meta .assessment-start-meta-item", text: "1 Question"
    assert_select ".assessment-content[data-assessment-target='content']"
    assert_select ".assessment-content.is-active", false
  end
end
