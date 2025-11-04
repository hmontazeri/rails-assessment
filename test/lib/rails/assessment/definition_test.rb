require "test_helper"

module Rails
  module Assessment
    class DefinitionTest < ActiveSupport::TestCase
      test "initializes with notification_email" do
        definition = Definition.new(notification_email: "leads@example.com")

        assert_equal "leads@example.com", definition.notification_email
      end

      test "initializes with webhook_url" do
        definition = Definition.new(webhook_url: "https://example.com/webhook")

        assert_equal "https://example.com/webhook", definition.webhook_url
      end

      test "initializes with capture_email" do
        definition = Definition.new(capture_email: true)

        assert_equal true, definition.capture_email
      end

      test "initializes with capture_name" do
        definition = Definition.new(capture_name: true)

        assert_equal true, definition.capture_name
      end

      test "defaults capture_email to false" do
        definition = Definition.new({})

        assert_equal false, definition.capture_email
      end

      test "defaults capture_name to false" do
        definition = Definition.new({})

        assert_equal false, definition.capture_name
      end

      test "defaults notification_email to nil" do
        definition = Definition.new({})

        assert_nil definition.notification_email
      end

      test "defaults webhook_url to nil" do
        definition = Definition.new({})

        assert_nil definition.webhook_url
      end

      test "from_hash loads notification_email" do
        hash = {
          title: "Test",
          notification_email: "leads@example.com"
        }

        definition = Definition.from_hash(hash)

        assert_equal "leads@example.com", definition.notification_email
      end

      test "from_hash loads webhook_url" do
        hash = {
          title: "Test",
          webhook_url: "https://example.com/webhook"
        }

        definition = Definition.from_hash(hash)

        assert_equal "https://example.com/webhook", definition.webhook_url
      end

      test "from_hash loads capture_email" do
        hash = {
          title: "Test",
          capture_email: true
        }

        definition = Definition.from_hash(hash)

        assert_equal true, definition.capture_email
      end

      test "from_hash loads capture_name" do
        hash = {
          title: "Test",
          capture_name: true
        }

        definition = Definition.from_hash(hash)

        assert_equal true, definition.capture_name
      end

      test "from_hash loads all new fields together" do
        hash = {
          title: "Test Assessment",
          slug: "test-assessment",
          notification_email: "leads@example.com",
          webhook_url: "https://example.com/webhook",
          capture_email: true,
          capture_name: true,
          questions: [],
          result_rules: []
        }

        definition = Definition.from_hash(hash)

        assert_equal "Test Assessment", definition.title
        assert_equal "test-assessment", definition.slug
        assert_equal "leads@example.com", definition.notification_email
        assert_equal "https://example.com/webhook", definition.webhook_url
        assert_equal true, definition.capture_email
        assert_equal true, definition.capture_name
      end

      test "deep_symbolize preserves nested structures with new fields" do
        hash = {
          "title" => "Test",
          "notification_email" => "leads@example.com",
          "capture_email" => true,
          "questions" => []
        }

        definition = Definition.from_hash(hash)

        assert_equal "leads@example.com", definition.notification_email
        assert_equal true, definition.capture_email
      end

      test "result rule payload can include cta_url" do
        hash = {
          text: "Test Result",
          payload: {
            headline: "Test",
            cta_text: "Click Here",
            cta_url: "https://example.com/consultation"
          }
        }

        result_rule = ResultRule.from_hash(hash)

        assert_equal "https://example.com/consultation", result_rule.payload[:cta_url]
      end

      test "result rule payload with cta_url and cta_text" do
        hash = {
          text: "Test Result",
          payload: {
            headline: "Test",
            cta_text: "Schedule Now",
            cta_url: "https://calendly.com/example"
          }
        }

        result_rule = ResultRule.from_hash(hash)

        assert_equal "Schedule Now", result_rule.payload[:cta_text]
        assert_equal "https://calendly.com/example", result_rule.payload[:cta_url]
      end
    end
  end
end
