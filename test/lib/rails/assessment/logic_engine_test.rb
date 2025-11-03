require "test_helper"

module Rails
  module Assessment
    class LogicEngineTest < ActiveSupport::TestCase
      def setup
        @rules = [
          ResultRule.new(text: "Match", all_tags: %w[wifi_ok]),
          ResultRule.new(text: "Match two", any_tags: %w[wifi_bad]),
          ResultRule.new(text: "Fallback", fallback: true)
        ]
      end

      test "matches rule when all tags satisfied" do
        rule = LogicEngine.evaluate(%w[wifi_ok], @rules, fallback_text: "default")
        assert_equal "Match", rule.text
      end

      test "matches rule when any tag satisfied" do
        rule = LogicEngine.evaluate(%w[wifi_bad], @rules)
        assert_equal "Match two", rule.text
      end

      test "falls back to fallback rule" do
        rule = LogicEngine.evaluate(%w[unknown], @rules, fallback_text: "fallback text")
        assert_equal "Fallback", rule.text
      end

      test "builds fallback result from text" do
        rule = LogicEngine.evaluate(%w[unknown], [], fallback_text: "Generated")
        assert_equal "Generated", rule.text
        assert rule.fallback?
      end
    end
  end
end
