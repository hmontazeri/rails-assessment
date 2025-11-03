require "pathname"

module Rails
  module Assessment
    class Configuration
      attr_accessor :theme,
                    :themes,
                    :theme_strategy,
                    :theme_param_key,
                    :theme_proc,
                    :assessments_paths,
                    :cache_enabled,
                    :fallback_result_text

      def initialize
        @theme = default_theme
        @themes = {}
        @theme_strategy = :initializer
        @theme_param_key = :theme
        @theme_proc = nil
        @assessments_paths = default_assessment_paths
        @cache_enabled = !rails_env_development?
        @fallback_result_text = "Thanks for completing the assessment."
      end

      def assessments_paths=(paths)
        @assessments_paths = Array(paths).compact.map { |path| Pathname.new(path) }
      end

      def theme_for(request: nil, override: nil)
        override_hash = override ? deep_symbolize(override) : nil

        case theme_strategy
        when :initializer
          theme.deep_merge(override_hash || {})
        when :param
          resolve_param_theme(request).deep_merge(override_hash || {})
        when :proc
          resolved = theme_proc&.call(request)
          base_theme.deep_merge(deep_symbolize(resolved || {})).deep_merge(override_hash || {})
        else
          base_theme.deep_merge(override_hash || {})
        end
      end

      def base_theme
        deep_symbolize(theme || {})
      end

      private

      def resolve_param_theme(request)
        return base_theme unless request

        key = Array(theme_param_key).map(&:to_s).find do |param_key|
          !param_value(request, param_key).nil?
        end
        return base_theme unless key

        value = param_value(request, key)
        resolved = themes[value.to_s] || themes[value.to_sym]
        return base_theme unless resolved

        base_theme.deep_merge(deep_symbolize(resolved))
      end

      def deep_symbolize(value)
        case value
        when Hash
          value.each_with_object({}) do |(k, v), acc|
            acc[normalize_key(k)] = deep_symbolize(v)
          end
        when Array
          value.map { |item| deep_symbolize(item) }
        else
          value
        end
      end

      def default_theme
        {
          colors: {
            primary: "#2563EB",
            neutral: {
              50 => "#F9FAFB",
              900 => "#111827"
            }
          },
          typography: {
            font_sans: "system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif",
            heading: :sans,
            body: :sans
          },
          radius: {
            sm: "0.375rem",
            lg: "0.75rem"
          },
          shadow: {
            card: "0 10px 30px rgba(15, 23, 42, 0.08)"
          },
          dark_mode: {
            enabled: false
          }
        }
      end

      def default_assessment_paths
        if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
          [ Rails.root.join("config", "assessments") ]
        else
          [ Pathname.new("config/assessments") ]
        end
      end

      def rails_env_development?
        defined?(Rails) && Rails.respond_to?(:env) && Rails.env&.development?
      end

      def normalize_key(key)
        case key
        when String
          key.to_sym
        when Symbol, Numeric
          key
        else
          key.respond_to?(:to_sym) ? key.to_sym : key
        end
      end

      def param_value(request, key)
        return unless request

        [
          params_hash(request),
          request_hash(request, :query_parameters),
          request_hash(request, :request_parameters),
          request_hash(request, :path_parameters)
        ].compact.each do |source|
          return source[key] if source.key?(key)
          sym_key = key.to_sym
          return source[sym_key] if source.key?(sym_key)
        end

        nil
      end

      def request_hash(request, method_name)
        return unless request.respond_to?(method_name)

        params = request.public_send(method_name)
        to_hash(params)
      end

      def params_hash(request)
        return unless request.respond_to?(:params)

        to_hash(request.params)
      end

      def to_hash(object)
        case object
        when nil
          nil
        when Hash
          object
        else
          if object.respond_to?(:to_unsafe_h)
            object.to_unsafe_h
          elsif object.respond_to?(:to_h)
            object.to_h
          else
            nil
          end
        end
      end
    end
  end
end
