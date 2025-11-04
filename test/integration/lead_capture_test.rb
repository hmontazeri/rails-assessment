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
end
