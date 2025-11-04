module Rails
  module Assessment
    module ApplicationHelper
      # Safely access nested payload data from a result rule
      # @param result_rule [ResultRule] the result rule object
      # @param key [String, Symbol] the payload key to access
      # @param default [Object] default value if key doesn't exist
      # @return [Object] the payload value or default
      def result_payload(result_rule, key, default = nil)
        return default unless result_rule&.payload.is_a?(Hash)
        result_rule.payload.fetch(key.to_sym, default)
      end

      # Format and display a score
      # @param score [Integer] the score value
      # @param max_score [Integer] maximum possible score
      # @return [String] formatted score display
      def display_score(score, max_score = 100)
        return "—" if score.nil?
        "#{score} / #{max_score}"
      end

      # Calculate score as percentage
      # @param score [Integer] the score value
      # @param max_score [Integer] maximum possible score
      # @return [Integer] percentage (0-100)
      def score_percentage(score, max_score = 100)
        return 0 if score.nil? || max_score.zero?
        ((score.to_f / max_score) * 100).round
      end

      # Get user's name from response data
      # @param response [Response] the response object
      # @return [String, nil] the user's name if captured
      def user_name(response)
        return nil unless response&.answers.is_a?(Hash)
        response.answers.dig("lead", "name")
      end

      # Get user's email from response data
      # @param response [Response] the response object
      # @return [String, nil] the user's email if captured
      def user_email(response)
        return nil unless response&.answers.is_a?(Hash)
        response.answers.dig("lead", "email")
      end
    end
  end
end
