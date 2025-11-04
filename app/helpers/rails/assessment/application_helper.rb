require "uri"
require "cgi"

module Rails
  module Assessment
    module ApplicationHelper
      include Rails::Assessment::Engine.routes.url_helpers
      # Safely access nested payload data from a result rule
      # @param result_rule [ResultRule] the result rule object
      # @param key [String, Symbol] the payload key to access
      # @param default [Object] default value if key doesn't exist
      # @return [Object] the payload value or default
      def result_payload(result_rule, key, default = nil)
        return default unless result_rule&.payload.is_a?(Hash)
        result_rule.payload.fetch(key.to_sym, default)
      end

      # Determine CTA URL including response UUID when provided
      # @param raw_url [String, nil] CTA URL from payload
      # @param slug [String] assessment slug
      # @param response [Response] response object with UUID
      # @return [String] final CTA URL to use
      def result_cta_url(raw_url, slug, response)
        fallback_url = assessment_path(slug)
        return fallback_url if raw_url.blank?
        return raw_url if response.nil? || response.uuid.blank?

        append_uuid_param(raw_url, response.uuid)
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

      private

      def append_uuid_param(url, uuid)
        uri = URI.parse(url)
        existing_params = uri.query ? CGI.parse(uri.query).transform_values(&:first) : {}
        existing_params = existing_params.transform_keys(&:to_s)
        existing_params["response_uuid"] = uuid
        uri.query = existing_params.to_query
        uri.to_s
      rescue URI::InvalidURIError
        url
      end
    end
  end
end
