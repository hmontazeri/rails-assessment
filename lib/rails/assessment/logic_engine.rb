module Rails
  module Assessment
    class LogicEngine
      class << self
        def evaluate(selected_tags, result_rules, score: nil, fallback_text: nil)
          rules = Array(result_rules)
          tags = normalize_tags(selected_tags)

          matching_rule = rules.find { |rule| rule.match?(tags, score: score) }
          return matching_rule if matching_rule

          fallback_rule = rules.reverse.find(&:fallback?)
          return fallback_rule if fallback_rule

          build_fallback_result(fallback_text)
        end

        private

        def normalize_tags(tags)
          Array(tags).compact.map(&:to_s)
        end

        def build_fallback_result(text)
          return nil if text.nil?

          Rails::Assessment::ResultRule.new(
            id: "fallback",
            text: text,
            fallback: true
          )
        end
      end
    end
  end
end
