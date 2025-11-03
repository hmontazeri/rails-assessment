require "test_helper"

module Rails
  module Assessment
    class ResponseBuilderTest < ActiveSupport::TestCase
      def setup
        @definition = Definition.new(
          slug: "demo",
          questions: [
            Question.from_hash(
              id: "wifi",
              text: "Wifi?",
              options: [
                { id: "wifi_ok", text: "Yes", tag: :wifi_ok, score: 2 },
                { id: "wifi_bad", text: "No", tag: :wifi_bad, score: 0 }
              ]
            ),
            Question.from_hash(
              id: "usage",
              text: "Devices",
              multi_select: true,
              options: [
                { id: "lights", text: "Lights", tag: :lights, score: 1 },
                { id: "security", text: "Security", tag: :security, score: 1 }
              ]
            )
          ]
        )
      end

      test "builds answer payload for single selection" do
        builder = ResponseBuilder.new(@definition)
        answers = builder.build({ "wifi" => "wifi_ok" })

        assert_equal "Wifi?", answers["wifi"]["question"]
        assert_equal "wifi_ok", answers["wifi"]["option"]["tag"]
        assert_equal 2, answers["wifi"]["score"]
      end

      test "builds answer payload for multi select" do
        builder = ResponseBuilder.new(@definition)
        answers = builder.build({ "usage" => %w[lights security] })

        assert_equal 2, answers["usage"]["options"].size
        assert_equal %w[lights security], answers["usage"]["tags"]
        assert_equal 2, answers["usage"]["score"]
      end

      test "skips optional question without answer" do
        @definition.questions.last.required = false
        builder = ResponseBuilder.new(@definition)
        answers = builder.build({})

        refute answers.key?("usage")
        assert_empty answers
      end
    end
  end
end
