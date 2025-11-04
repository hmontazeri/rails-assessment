module Rails
  module Assessment
    class Definition
      attr_accessor :title, :slug, :hook, :description, :questions, :result_rules, :theme, :metadata, :estimated_time, :show_start_screen, :logo, :show_question_count

      def initialize(attributes = {})
        @title = attributes[:title]
        @slug = attributes[:slug]&.to_s
        @hook = attributes[:hook]
        @description = attributes[:description]
        @questions = attributes[:questions] || []
        @result_rules = attributes[:result_rules] || []
        @theme = Definition.send(:deep_symbolize, attributes[:theme] || {})
        @metadata = attributes[:metadata] || {}
        @estimated_time = attributes[:estimated_time]
        @show_start_screen = attributes.key?(:show_start_screen) ? attributes[:show_start_screen] : false
        @logo = attributes[:logo]
        @show_question_count = attributes.key?(:show_question_count) ? attributes[:show_question_count] : true
      end

      def add_question(question)
        questions << question
      end

      def add_result_rule(rule)
        result_rules << rule
      end

      def theme_override?
        theme.any?
      end

      def self.from_hash(hash)
        symbolized = deep_symbolize(hash)
        slug = symbolized[:slug] || parameterize(symbolized[:title])
        definition = new(
          title: symbolized[:title],
          slug: slug,
          hook: symbolized[:hook],
          description: symbolized[:description],
          theme: symbolized[:theme],
          metadata: symbolized[:metadata],
          estimated_time: symbolized[:estimated_time],
          show_start_screen: symbolized[:show_start_screen],
          logo: symbolized[:logo],
          show_question_count: symbolized[:show_question_count]
        )

        Array(symbolized[:questions]).each do |question_hash|
          definition.add_question(Question.from_hash(question_hash))
        end

        Array(symbolized[:result_rules]).each do |rule_hash|
          definition.add_result_rule(ResultRule.from_hash(rule_hash))
        end

        definition
      end

      def self.parameterize(value)
        return if value.nil?

        value.to_s.parameterize
      end

      def self.deep_symbolize(value)
        case value
        when Hash
          value.each_with_object({}) do |(k, v), acc|
            acc[k.to_sym] = deep_symbolize(v)
          end
        when Array
          value.map { |entry| deep_symbolize(entry) }
        else
          value
        end
      end

      private_class_method :deep_symbolize
    end

    class Question
      attr_accessor :id,
                    :text,
                    :help_text,
                    :options,
                    :multi_select,
                    :required,
                    :meta

      def initialize(attributes = {})
        @id = attributes[:id]&.to_s
        @text = attributes[:text]
        @help_text = attributes[:help_text]
        @multi_select = attributes[:multi_select] || false
        @required = attributes.key?(:required) ? attributes[:required] : true
        @meta = attributes[:meta] || {}
        @options = attributes[:options] || []
      end

      def add_option(option)
        options << option
      end

      def allow_multiple?
        multi_select
      end

      def required?
        required
      end

      def self.from_hash(hash)
        symbolized = Definition.send(:deep_symbolize, hash)
        id = symbolized[:id] || Definition.parameterize(symbolized[:text])
        question = new(
          id: id,
          text: symbolized[:text],
          help_text: symbolized[:help_text],
          multi_select: symbolized[:multi_select],
          required: symbolized[:required],
          meta: symbolized[:meta]
        )

        Array(symbolized[:options]).each do |option_hash|
          question.add_option(QuestionOption.from_hash(option_hash))
        end

        question
      end
    end

    class QuestionOption
      attr_accessor :id,
                    :text,
                    :tag,
                    :value,
                    :score,
                    :next_question,
                    :meta

      def initialize(attributes = {})
        @id = attributes[:id]&.to_s
        @text = attributes[:text]
        @tag = attributes[:tag]&.to_s
        @value = attributes.key?(:value) ? attributes[:value] : attributes[:tag]
        @score = attributes[:score]
        @next_question = attributes[:next_question]&.to_s
        @meta = attributes[:meta] || {}
      end

      def self.from_hash(hash)
        symbolized = Definition.send(:deep_symbolize, hash)
        id = symbolized[:id] || Definition.parameterize(symbolized[:text])
        new(
          id: id,
          text: symbolized[:text],
          tag: symbolized[:tag],
          value: symbolized[:value],
          score: symbolized[:score],
          next_question: symbolized[:next_question],
          meta: symbolized[:meta]
        )
      end
    end

    class ResultRule
      attr_accessor :id,
                    :text,
                    :all_tags,
                    :any_tags,
                    :exclude_tags,
                    :score_at_least,
                    :score_at_most,
                    :payload,
                    :fallback,
                    :meta

      def initialize(attributes = {})
        @id = attributes[:id]&.to_s
        @text = attributes[:text]
        @all_tags = normalize_array(attributes[:all_tags] || attributes[:tags])
        @any_tags = normalize_array(attributes[:any_tags])
        @exclude_tags = normalize_array(attributes[:exclude_tags])
        @score_at_least = attributes[:score_at_least]
        @score_at_most = attributes[:score_at_most]
        @payload = attributes[:payload] || {}
        @fallback = attributes[:fallback] || false
        @meta = attributes[:meta] || {}
      end

      def fallback?
        fallback
      end

      def match?(selected_tags, score: nil)
        tags = normalize_array(selected_tags)

        return false unless all_tags.all? { |tag| tags.include?(tag) }
        return false if any_tags.any? && (tags & any_tags).empty?
        return false if exclude_tags.any? && (tags & exclude_tags).any?
        return false unless score_satisfied?(score)

        true
      end

      def self.from_hash(hash)
        symbolized = Definition.send(:deep_symbolize, hash)
        id = symbolized[:id] || Definition.parameterize(symbolized[:text])
        new(
          id: id,
          text: symbolized[:text],
          all_tags: symbolized[:all_tags] || symbolized[:tags],
          any_tags: symbolized[:any_tags],
          exclude_tags: symbolized[:exclude_tags],
          score_at_least: symbolized[:score_at_least] || symbolized[:min_score],
          score_at_most: symbolized[:score_at_most] || symbolized[:max_score],
          payload: symbolized[:payload],
          fallback: symbolized[:fallback],
          meta: symbolized[:meta]
        )
      end

      private

      def score_satisfied?(score)
        return true if score.nil? && score_at_least.nil? && score_at_most.nil?
        return false if score.nil? && (score_at_least || score_at_most)

        return false if score_at_least && score < score_at_least
        return false if score_at_most && score > score_at_most

        true
      end

      def normalize_array(collection)
        Array(collection).compact.map(&:to_s)
      end
    end
  end
end
