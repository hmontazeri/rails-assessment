require "net/http"
require "json"

module Rails
  module Assessment
    class WebhookService
      def self.post_lead(response, webhook_url)
        new(response, webhook_url).call
      end

      def initialize(response, webhook_url)
        @response = response
        @webhook_url = webhook_url
      end

      def call
        return if @webhook_url.blank?

        begin
          uri = URI(@webhook_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true if uri.scheme == "https"

          request = Net::HTTP::Post.new(uri.path)
          request["Content-Type"] = "application/json"
          request.body = payload.to_json

          response = http.request(request)

          log_webhook_result(response)
        rescue StandardError => e
          log_webhook_error(e)
        end
      end

      private

      def payload
        {
          response_id: @response.id,
          response_uuid: @response.uuid,
          assessment_slug: @response.assessment_slug,
          lead: {
            name: @response.answers.dig("lead", "name"),
            email: @response.answers.dig("lead", "email")
          },
          score: @response.score,
          result: @response.result,
          tags: @response.tags,
          created_at: @response.created_at.iso8601,
          answers: @response.answers
        }
      end

      def log_webhook_result(response)
        Rails.logger.info("[Rails::Assessment] Webhook posted successfully. Status: #{response.code}")
      end

      def log_webhook_error(error)
        Rails.logger.error("[Rails::Assessment] Webhook delivery failed: #{error.message}")
      end
    end
  end
end
