module Rails
  module Assessment
    module DSL
      class Builder
        attr_reader :definition

        def initialize(slug, **attributes, &block)
          @definition = Rails::Assessment::Definition.new(
            slug: slug,
            title: attributes[:title],
            hook: attributes[:hook],
            description: attributes[:description],
            theme: attributes[:theme],
            metadata: attributes[:metadata]
          )
          instance_eval(&block) if block_given?
        end

        def title(value)
          definition.title = value
        end

        def hook(value)
          definition.hook = value
        end

        def description(value)
          definition.description = value
        end

        def theme(hash)
          definition.theme = Definition.send(:deep_symbolize, hash)
        end

        def metadata(hash)
          definition.metadata = hash
        end

        def estimated_time(value)
          definition.estimated_time = value
        end

        def show_start_screen(value = true)
          definition.show_start_screen = value
        end

        def show_question_count(value = true)
          definition.show_question_count = value
        end

        def logo(value)
          definition.logo = value
        end

        def notification_email(value)
          definition.notification_email = value
        end

        def webhook_url(value)
          definition.webhook_url = value
        end

        def capture_email(value = true)
          definition.capture_email = value
        end

        def capture_name(value = true)
          definition.capture_name = value
        end

        def question(text = nil, id: nil, multi_select: false, required: true, help_text: nil, **opts, &block)
          question = Rails::Assessment::Question.new(
            id: id || Rails::Assessment::Definition.parameterize(text),
            text: text,
            multi_select: multi_select,
            required: required,
            help_text: help_text,
            meta: opts[:meta]
          )

          if block_given?
            QuestionBuilder.new(question).instance_eval(&block)
          else
            Array(opts[:options]).each do |option_hash|
              question.add_option(Rails::Assessment::QuestionOption.new(option_hash))
            end
          end

          definition.add_question(question)
          question
        end

        def result_rule(text = nil, **opts, &block)
          rule = Rails::Assessment::ResultRule.new(
            text: text,
            all_tags: pick_tags(opts),
            any_tags: opts[:any_tags],
            exclude_tags: opts[:exclude_tags],
            score_at_least: opts[:score_at_least] || opts[:min_score],
            score_at_most: opts[:score_at_most] || opts[:max_score],
            payload: opts[:payload],
            fallback: opts[:fallback] || false,
            meta: opts[:meta]
          )

          if block_given?
            RuleBuilder.new(rule).instance_eval(&block)
          end

          definition.add_result_rule(rule)
          rule
        end

        def fallback(text, **opts)
          definition.add_result_rule(
            Rails::Assessment::ResultRule.new(
              text: text,
              fallback: true,
              payload: opts[:payload],
              meta: opts[:meta]
            )
          )
        end

        private

        def pick_tags(options)
          options[:all_tags] || options[:tags]
        end
      end

      class QuestionBuilder
        def initialize(question)
          @question = question
        end

        def option(text, tag: nil, value: nil, score: nil, next_question: nil, id: nil, meta: nil)
          @question.add_option(
            Rails::Assessment::QuestionOption.new(
              id: id,
              text: text,
              tag: tag,
              value: value,
              score: score,
              next_question: next_question,
              meta: meta
            )
          )
        end
      end

      class RuleBuilder
        def initialize(rule)
          @rule = rule
        end

        def tags(*list)
          @rule.all_tags = list.flatten.compact.map(&:to_s)
        end

        def any_tags(*list)
          @rule.any_tags = list.flatten.compact.map(&:to_s)
        end

        def exclude_tags(*list)
          @rule.exclude_tags = list.flatten.compact.map(&:to_s)
        end

        def score_at_least(value)
          @rule.score_at_least = value
        end

        def score_at_most(value)
          @rule.score_at_most = value
        end

        def payload(hash)
          @rule.payload = hash
        end
      end
    end
  end
end
