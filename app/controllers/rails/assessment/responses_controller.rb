module Rails
  module Assessment
    class ResponsesController < ApplicationController
      before_action :load_definition

      def create
        builder = Rails::Assessment::ResponseBuilder.new(@definition)
        answers = builder.build(response_params)

        missing = @definition.questions.select(&:required?).reject { |question| answers.key?(question.id) }
        unless missing.empty?
          flash.now[:alert] = "Bitte beantworten Sie alle erforderlichen Fragen."
          @response = Response.new(assessment_slug: @definition.slug, answers: answers)
          @theme = Rails::Assessment::Theme::Resolver.new.resolve(request: request, overrides: @definition.theme)
          render "rails/assessment/assessments/show", status: :unprocessable_entity
          return
        end

        @response = Response.new(
          assessment_slug: @definition.slug,
          answers: answers
        )

        result_rule = Rails::Assessment::LogicEngine.evaluate(
          @response.tags,
          @definition.result_rules,
          score: @response.score,
          fallback_text: Rails::Assessment.configuration.fallback_result_text
        )
        @response.result = result_rule&.text

        if @response.save
          # Send lead notifications if configured
          if @definition.notification_email.present? && @response.answers.dig("lead", "email").present?
            LeadNotificationMailer.new_lead(@response, @definition.notification_email).deliver_later
          end

          # Post lead data to webhook if configured
          if @definition.webhook_url.present?
            WebhookService.post_lead(@response, @definition.webhook_url)
          end

          redirect_to assessment_result_path(@definition.slug, response_uuid: @response.uuid)
        else
          flash.now[:alert] = "Bitte füllen Sie alle Pflichtfelder aus."
          @theme = Rails::Assessment::Theme::Resolver.new.resolve(request: request, overrides: @definition.theme)
          render "rails/assessment/assessments/show", status: :unprocessable_entity
        end
      end

      private

      def load_definition
        Rails::Assessment.load! if reload_required?

        @definition = Rails::Assessment.find(params[:assessment_slug] || params[:slug])
        raise ActionController::RoutingError, "Assessment not found" unless @definition
      end

      def response_params
        params.fetch(:response, {}).permit!
      end

      def reload_required?
        config = Rails::Assessment.configuration
        return false unless config
        return false unless config.cache_enabled == false

        true
      end
    end
  end
end
