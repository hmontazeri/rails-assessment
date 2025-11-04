module Rails
  module Assessment
    class AssessmentsController < ApplicationController
      before_action :load_definition

      def show
        @response = Response.new(assessment_slug: @definition.slug)
        @theme = theme_resolver.resolve(request: request, overrides: @definition.theme)
      end

      def result
        @response = Response.find_by(uuid: params[:response_uuid], assessment_slug: @definition.slug)
        unless @response
          redirect_to assessment_path(@definition.slug), alert: "Assessment response not found."
          return
        end

        @result_rule = Rails::Assessment::LogicEngine.evaluate(
          @response.tags,
          @definition.result_rules,
          score: @response.score,
          fallback_text: Rails::Assessment.configuration.fallback_result_text
        )
        @theme = theme_resolver.resolve(request: request, overrides: @definition.theme)
      end

      private

      def load_definition
        Rails::Assessment.load! if reload_required?

        @definition = Rails::Assessment.find(params[:assessment_slug] || params[:slug])
        raise ActionController::RoutingError, "Assessment not found" unless @definition
      end

      def reload_required?
        config = Rails::Assessment.configuration
        return false unless config
        return false unless config.cache_enabled == false

        true
      end

      def theme_resolver
        @theme_resolver ||= Rails::Assessment::Theme::Resolver.new
      end
    end
  end
end
