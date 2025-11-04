require "test_helper"

module Rails
  module Assessment
    class WebhookServiceTest < ActiveSupport::TestCase
      setup do
        @response = Response.create!(
          assessment_slug: "test-assessment",
          answers: {
            "lead" => {
              "name" => "John Doe",
              "email" => "john@example.com"
            },
            "q1" => {
              "question" => "Test Question",
              "option" => { "text" => "Yes" },
              "tags" => [ "yes" ],
              "score" => 5
            }
          },
          result: "Test Result",
          created_at: Time.parse("2024-01-15T10:30:00Z")
        )
      end

      teardown do
        @response.destroy if @response.persisted?
        WebMock.reset!
      end

      test "posts to webhook URL with POST request" do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: "OK")

        WebhookService.post_lead(@response, "https://example.com/webhook")

        assert_requested(:post, "https://example.com/webhook")
      end

      test "sends response identifiers in payload" do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: "OK")

        WebhookService.post_lead(@response, "https://example.com/webhook")

        assert_requested(:post, "https://example.com/webhook") do |req|
          json = JSON.parse(req.body)
          assert_equal @response.id, json["response_id"]
          assert_equal @response.uuid, json["response_uuid"]
        end
      end

      test "sends assessment_slug in payload" do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: "OK")

        WebhookService.post_lead(@response, "https://example.com/webhook")

        assert_requested(:post, "https://example.com/webhook") do |req|
          json = JSON.parse(req.body)
          assert_equal "test-assessment", json["assessment_slug"]
        end
      end

      test "sends lead data in payload" do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: "OK")

        WebhookService.post_lead(@response, "https://example.com/webhook")

        assert_requested(:post, "https://example.com/webhook") do |req|
          json = JSON.parse(req.body)
          assert_equal "John Doe", json["lead"]["name"]
          assert_equal "john@example.com", json["lead"]["email"]
        end
      end

      test "sends score in payload" do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: "OK")

        WebhookService.post_lead(@response, "https://example.com/webhook")

        assert_requested(:post, "https://example.com/webhook") do |req|
          json = JSON.parse(req.body)
          assert_equal 5, json["score"]
        end
      end

      test "sends result in payload" do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: "OK")

        WebhookService.post_lead(@response, "https://example.com/webhook")

        assert_requested(:post, "https://example.com/webhook") do |req|
          json = JSON.parse(req.body)
          assert_equal "Test Result", json["result"]
        end
      end

      test "sends tags in payload" do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: "OK")

        WebhookService.post_lead(@response, "https://example.com/webhook")

        assert_requested(:post, "https://example.com/webhook") do |req|
          json = JSON.parse(req.body)
          assert_equal [ "yes" ], json["tags"]
        end
      end

      test "sends created_at timestamp in ISO8601 format" do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: "OK")

        WebhookService.post_lead(@response, "https://example.com/webhook")

        assert_requested(:post, "https://example.com/webhook") do |req|
          json = JSON.parse(req.body)
          assert_equal "2024-01-15T10:30:00Z", json["created_at"]
        end
      end

      test "sends full answers in payload" do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: "OK")

        WebhookService.post_lead(@response, "https://example.com/webhook")

        assert_requested(:post, "https://example.com/webhook") do |req|
          json = JSON.parse(req.body)
          assert json["answers"].key?("lead")
          assert json["answers"].key?("q1")
        end
      end

      test "sets correct Content-Type header" do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: "OK")

        WebhookService.post_lead(@response, "https://example.com/webhook")

        assert_requested(:post, "https://example.com/webhook") do |req|
          assert_equal "application/json", req.headers["Content-Type"]
        end
      end

      test "does not post when webhook_url is blank" do
        WebhookService.post_lead(@response, nil)

        assert_not_requested(:post, %r{.*})
      end

      test "does not post when webhook_url is empty string" do
        WebhookService.post_lead(@response, "")

        assert_not_requested(:post, %r{.*})
      end

      test "handles webhook failure gracefully" do
        stub_request(:post, "https://example.com/webhook")
          .to_raise(StandardError.new("Connection failed"))

        # Should not raise, should log error
        assert_nothing_raised do
          WebhookService.post_lead(@response, "https://example.com/webhook")
        end
      end

      test "works with HTTPS URLs" do
        stub_request(:post, "https://secure.example.com/webhook")
          .to_return(status: 200, body: "OK")

        WebhookService.post_lead(@response, "https://secure.example.com/webhook")

        assert_requested(:post, "https://secure.example.com/webhook")
      end

      test "works with HTTP URLs" do
        stub_request(:post, "http://example.com/webhook")
          .to_return(status: 200, body: "OK")

        WebhookService.post_lead(@response, "http://example.com/webhook")

        assert_requested(:post, "http://example.com/webhook")
      end
    end
  end
end
