require "test_helper"

module Rails
  module Assessment
    class LeadNotificationMailerTest < ActionMailer::TestCase
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
              "option" => { "text" => "Yes", "tag" => "yes", "score" => 5 },
              "tags" => [ "yes" ],
              "score" => 5
            }
          },
          result: "Test Result"
        )
      end

      teardown do
        @response.destroy if @response.persisted?
      end

      test "sends email with correct recipient" do
        email = LeadNotificationMailer.new_lead(@response, "leads@example.com")

        assert_equal [ "leads@example.com" ], email.to
      end

      test "includes lead name in subject when available" do
        email = LeadNotificationMailer.new_lead(@response, "leads@example.com")

        assert_includes email.subject, "John Doe"
        assert_includes email.subject, "test-assessment"
      end

      test "includes lead name in email when available" do
        email = LeadNotificationMailer.new_lead(@response, "leads@example.com")

        assert_includes email.body.encoded, "John Doe"
      end

      test "includes lead email in email" do
        email = LeadNotificationMailer.new_lead(@response, "leads@example.com")

        assert_includes email.body.encoded, "john@example.com"
      end

      test "includes assessment slug in email" do
        email = LeadNotificationMailer.new_lead(@response, "leads@example.com")

        assert_includes email.body.encoded, "test-assessment"
      end

      test "includes score in email" do
        email = LeadNotificationMailer.new_lead(@response, "leads@example.com")

        assert_includes email.body.encoded, "5"
      end

      test "includes result in email" do
        email = LeadNotificationMailer.new_lead(@response, "leads@example.com")

        assert_includes email.body.encoded, "Test Result"
      end

      test "includes tags in email" do
        email = LeadNotificationMailer.new_lead(@response, "leads@example.com")

        assert_includes email.body.encoded, "yes"
      end

      test "handles response without lead name" do
        @response.answers = {
          "lead" => {
            "email" => "jane@example.com"
          }
        }

        email = LeadNotificationMailer.new_lead(@response, "leads@example.com")

        assert_includes email.body.encoded, "jane@example.com"
      end

      test "handles response without lead data" do
        @response.answers = {}
        @response.stubs(:tags).returns([])

        email = LeadNotificationMailer.new_lead(@response, "leads@example.com")

        assert_equal [ "leads@example.com" ], email.to
        assert email.body.encoded.present?
      end

      test "renders html and text parts" do
        email = LeadNotificationMailer.new_lead(@response, "leads@example.com")

        assert email.multipart?
      end
    end
  end
end
