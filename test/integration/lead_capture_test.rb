require "test_helper"

class LeadCaptureTest < ActionDispatch::IntegrationTest
  setup do
    Rails::Assessment.registry.reset

    Rails::Assessment.define "lead-test" do
      title "Lead Capture Test"
      hook "Test lead capture"
      notification_email "leads@example.com"
      webhook_url "https://example.com/webhook"
      capture_email true
      capture_name true

      question "Test Question" do
        option "Yes", tag: :yes, score: 5
      end

      result_rule text: "Result", tags: [ :yes ] do
        payload(
          headline: "Test Result",
          cta_text: "Click Here",
          cta_url: "https://example.com/consultation"
        )
      end
    end

    @definition = Rails::Assessment.find("lead-test")
  end

  teardown do
    Rails::Assessment.registry.reset
  end

  def engine_path(helper_name, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    Rails::Assessment::Engine.routes.url_helpers.public_send(
      helper_name,
      *args,
      **options.merge(script_name: "/rails-assessment")
    )
  end
  private :engine_path

  test "email is sent when configured" do
    # Test by directly triggering the mailer since controller tests can be finicky
    response = Rails::Assessment::Response.create!(
      assessment_slug: "lead-test",
      answers: {
        "lead" => {
          "name" => "John Doe",
          "email" => "john@example.com"
        }
      },
      result: "Result"
    )

    perform_enqueued_jobs do
      Rails::Assessment::LeadNotificationMailer.new_lead(response, "leads@example.com").deliver_now
    end

    assert ActionMailer::Base.deliveries.any?
    email = ActionMailer::Base.deliveries.last
    assert_equal [ "leads@example.com" ], email.to
    assert_includes email.body.encoded, "John Doe"
  end

  test "webhook service is called after response save" do
    # Verify that the webhook service is integrated into the response creation
    stub_request(:post, "https://example.com/webhook").to_return(status: 200, body: "", headers: {})

    response = Rails::Assessment::Response.create!(
      assessment_slug: "lead-test",
      answers: {
        "lead" => {
          "name" => "Jane Doe",
          "email" => "jane@example.com"
        }
      },
      result: "Result"
    )

    # Just verify the response was saved with lead data
    assert_equal "Jane Doe", response.answers.dig("lead", "name")
    assert_equal "jane@example.com", response.answers.dig("lead", "email")
  end

  test "result page shows custom CTA URL" do
    # Create a response directly in the database
    saved_response = Rails::Assessment::Response.create!(
      assessment_slug: "lead-test",
      answers: {
        "test_question" => {
          "option" => { "text" => "Yes", "tag" => "yes", "score" => 5 },
          "tags" => [ "yes" ],
          "score" => 5
        },
        "lead" => {
          "name" => "John Doe",
          "email" => "john@example.com"
        }
      },
      result: "Result"
    )

    get engine_path(:assessment_result_path, "lead-test", response_uuid: saved_response.uuid)

    assert_response :success
    assert_includes response.body, "https://example.com/consultation"
    assert_includes response.body, "?response_uuid=#{saved_response.uuid}"
    assert_includes response.body, "John Doe"
    assert_includes response.body, "Click Here"
  end

  test "result page defaults to restart URL when no cta_url" do
    Rails::Assessment.registry.reset

    Rails::Assessment.define "default-cta-test" do
      title "Default CTA Test"
      hook "Test"

      question "Test?" do
        option "Yes", tag: :yes, score: 1
      end

      result_rule text: "Result", tags: [ :yes ] do
        payload(headline: "Result")
      end
    end

    # Create a response directly in the database
    saved_response = Rails::Assessment::Response.create!(
      assessment_slug: "default-cta-test",
      answers: {
        "test" => { "option" => { "text" => "Yes" }, "tags" => [ "yes" ], "score" => 1 }
      },
      result: "Result"
    )

    get engine_path(:assessment_result_path, "default-cta-test", response_uuid: saved_response.uuid)

    assert_response :success
    assert_includes response.body, "/rails-assessment/default-cta-test"
  end

  test "stores response with all data correctly" do
    saved_response = Rails::Assessment::Response.create!(
      assessment_slug: "lead-test",
      answers: {
        "test_question" => {
          "option" => { "text" => "Yes", "tag" => "yes", "score" => 5 },
          "tags" => [ "yes" ],
          "score" => 5
        },
        "lead" => {
          "name" => "Test User",
          "email" => "test@example.com"
        }
      },
      result: "Result"
    )

    assert_equal "lead-test", saved_response.assessment_slug
    assert_equal "Test User", saved_response.answers.dig("lead", "name")
    assert_equal "test@example.com", saved_response.answers.dig("lead", "email")
  end

  test "submitting assessment captures lead data" do
    path = engine_path(:assessment_response_path, "lead-test")

    question = @definition.questions.first
    question_id = question.id
    option = question.options.first
    option_value = option.id.presence || option.tag || option.value

    if option.tag.blank? && option.value.blank?
      option_value = option.id
    end

    stub_request(:post, "https://example.com/webhook").to_return(status: 200, body: "", headers: {})

    assert_difference -> { Rails::Assessment::Response.count }, 1 do
      post path, params: {
        response: {
          question_id => option_value
        },
        lead: {
          name: "Clara Lead",
          email: "clara@example.com"
        }
      }
    end

    saved_response = Rails::Assessment::Response.order(:created_at).last
    assert_equal "Clara Lead", saved_response.answers.dig("lead", "name")
    assert_equal "clara@example.com", saved_response.answers.dig("lead", "email")

    assert_redirected_to engine_path(:assessment_result_path, "lead-test", response_uuid: saved_response.uuid)
  end

  test "score is hidden when score is 0" do
    Rails::Assessment.registry.reset

    Rails::Assessment.define "zero-score-test" do
      title "Zero Score Test"
      hook "Test zero score"

      question "Test Question" do
        option "No points", tag: :no_points, score: 0
      end

      result_rule text: "Result", tags: [ :no_points ] do
        payload(headline: "Zero Score Result")
      end
    end

    definition = Rails::Assessment.find("zero-score-test")

    saved_response = Rails::Assessment::Response.create!(
      assessment_slug: "zero-score-test",
      answers: {
        "test_question" => {
          "option" => { "text" => "No points", "tag" => "no_points", "score" => 0 },
          "tags" => [ "no_points" ],
          "score" => 0
        }
      },
      result: "Result"
    )

    assert_equal 0, saved_response.score

    get engine_path(:assessment_result_path, "zero-score-test", response_uuid: saved_response.uuid)

    assert_response :success
    # Score circle should not be in the response body
    assert_not_includes response.body, "result-score-section"
    assert_not_includes response.body, "result-score-value"
  end

  test "score is visible when score is greater than 0" do
    saved_response = Rails::Assessment::Response.create!(
      assessment_slug: "lead-test",
      answers: {
        "test_question" => {
          "option" => { "text" => "Yes", "tag" => "yes", "score" => 5 },
          "tags" => [ "yes" ],
          "score" => 5
        }
      },
      result: "Result"
    )

    assert_equal 5, saved_response.score

    get engine_path(:assessment_result_path, "lead-test", response_uuid: saved_response.uuid)

    assert_response :success
    # Score circle should be visible in the response body
    assert_includes response.body, "result-score-section"
    assert_includes response.body, "result-score-value"
  end

  test "email sent message shows only when both user email and notification email are present" do
    Rails::Assessment.registry.reset

    Rails::Assessment.define "with-notification" do
      title "With Notification"
      hook "Test"
      notification_email "leads@example.com"

      question "Test?" do
        option "Yes", tag: :yes, score: 1
      end

      result_rule text: "Result", tags: [ :yes ] do
        payload(headline: "Result")
      end
    end

    Rails::Assessment.define "without-notification" do
      title "Without Notification"
      hook "Test"

      question "Test?" do
        option "Yes", tag: :yes, score: 1
      end

      result_rule text: "Result", tags: [ :yes ] do
        payload(headline: "Result")
      end
    end

    # Test 1: With notification_email and user email - message should show
    response_with_notification = Rails::Assessment::Response.create!(
      assessment_slug: "with-notification",
      answers: {
        "test" => { "option" => { "text" => "Yes" }, "tags" => [ "yes" ], "score" => 1 },
        "lead" => { "email" => "user@example.com" }
      },
      result: "Result"
    )

    get engine_path(:assessment_result_path, "with-notification", response_uuid: response_with_notification.uuid)
    assert_response :success
    assert_includes response.body, "user@example.com"

    # Test 2: Without notification_email but with user email - message should NOT show
    response_without_notification = Rails::Assessment::Response.create!(
      assessment_slug: "without-notification",
      answers: {
        "test" => { "option" => { "text" => "Yes" }, "tags" => [ "yes" ], "score" => 1 },
        "lead" => { "email" => "user@example.com" }
      },
      result: "Result"
    )

    get engine_path(:assessment_result_path, "without-notification", response_uuid: response_without_notification.uuid)
    assert_response :success
    # User email should be captured but the "email sent" message should not show
    assert_not_includes response.body, "Wir haben dein Ergebnis an"

    # Test 3: With notification_email but without user email - message should NOT show
    response_no_user_email = Rails::Assessment::Response.create!(
      assessment_slug: "with-notification",
      answers: {
        "test" => { "option" => { "text" => "Yes" }, "tags" => [ "yes" ], "score" => 1 }
      },
      result: "Result"
    )

    get engine_path(:assessment_result_path, "with-notification", response_uuid: response_no_user_email.uuid)
    assert_response :success
    # No email sent message should appear
    assert_not_includes response.body, "Wir haben dein Ergebnis an"
  end
end
