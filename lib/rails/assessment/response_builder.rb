module Rails
  module Assessment
    class ResponseBuilder
      def initialize(definition)
        @definition = definition
      end

      def build(params)
        answers = {}

        definition.questions.each do |question|
          selected = selected_options(question, params)
          next if selected.empty?

          answers[question.id] = serialize(question, selected)
        end

        answers
      end

      private

      attr_reader :definition

      def selected_options(question, params)
        raw_value = fetch_param(params, question.id)
        values = normalize_values(raw_value, question.allow_multiple?)

        values.filter_map { |value| find_option(question, value) }
      end

      def serialize(question, selected_options)
        tags = selected_options.map(&:tag).compact.map(&:to_s)
        score = selected_options.sum { |opt| opt.score.to_i }

        if question.allow_multiple?
          {
            "question" => question.text,
            "options" => selected_options.map { |opt| option_payload(opt) },
            "tags" => tags,
            "score" => score
          }
        else
          option = selected_options.first
          {
            "question" => question.text,
            "option" => option_payload(option),
            "tags" => tags,
            "score" => score
          }
        end
      end

      def option_payload(option)
        return nil unless option

        {
          "id" => option.id,
          "text" => option.text,
          "tag" => option.tag,
          "value" => option.value,
          "score" => option.score
        }
      end

      def normalize_values(raw_value, allow_multiple)
        values = Array(raw_value).flatten
        values = values.reject { |value| value.respond_to?(:blank?) ? value.blank? : value.nil? || value == "" }
        return values if allow_multiple

        values.first ? [ values.first ] : []
      end

      def fetch_param(params, key)
        params[key.to_s] || params[key.to_sym]
      end

      def find_option(question, value)
        return if value.nil?

        identifier = value.to_s
        question.options.find do |option|
          option.id == identifier ||
            option.tag == identifier ||
            option.value.to_s == identifier
        end
      end
    end
  end
end
