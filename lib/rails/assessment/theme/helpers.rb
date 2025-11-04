module Rails
  module Assessment
    module Theme
      module Helpers
        def current_assessment_theme(overrides: nil)
          @_rails_assessment_theme_cache ||= {}
          cache_key = overrides ? overrides.hash : :default
          @_rails_assessment_theme_cache[cache_key] ||= resolver.resolve(
            request: try(:request),
            overrides: overrides
          )
        end

        def assessment_dark_mode_enabled?(theme = current_assessment_theme)
          dark_mode = fetch_dark_mode(theme)
          dark_mode && truthy?(dark_mode[:enabled])
        end

        def assessment_dark_mode_default(theme = current_assessment_theme)
          dark_mode = fetch_dark_mode(theme)
          return unless dark_mode

          default = dark_mode[:default]
          default&.to_sym
        end

        def assessment_theme_variant(theme = current_assessment_theme, mode = :light)
          symbolized = deep_symbolize(theme || {})

          return symbolized unless mode.to_sym == :dark

          overrides = dark_mode_overrides(symbolized)
          return symbolized if overrides.empty?

          deep_merge_hash(symbolized, overrides)
        end

        def tkn(path, default: nil)
          keys = Array(path).flat_map { |key| key.to_s.split(".") }
          theme = current_assessment_theme

          keys.reduce(theme) do |acc, key|
            break default if acc.nil?

            if acc.is_a?(Hash)
              acc[key.to_sym] || acc[key.to_s]
            else
              default
            end
          end || default
        end

        def assessment_css_variables(theme = current_assessment_theme)
          flat = flatten_theme(theme)
          flat.map { |key, value| "--assessment-#{key}: #{value};" }.join(" ")
        end

        private

        def resolver
          @resolver ||= Rails::Assessment::Theme::Resolver.new
        end

        def flatten_theme(theme, parent_key = nil, result = {})
          Array(theme).each do |key, value|
            combined_key = [ parent_key, key.to_s.tr("_", "-") ].compact.join("-")
            if value.is_a?(Hash)
              flatten_theme(value, combined_key, result)
            else
              result[combined_key] = value
            end
          end

          result
        end

        def dark_mode_overrides(theme)
          dark_mode = fetch_dark_mode(theme)
          return {} unless dark_mode

          overrides = if dark_mode.key?(:overrides)
            deep_symbolize(dark_mode[:overrides])
          else
            dark_mode.reject { |key, _| [ :enabled, :default, :overrides ].include?(key) }
          end

          deep_symbolize(overrides || {})
        end

        def fetch_dark_mode(theme)
          return unless theme.is_a?(Hash)

          value = theme[:dark_mode] || theme["dark_mode"]
          return unless value.is_a?(Hash)

          deep_symbolize(value)
        end

        def deep_merge_hash(base, overrides)
          base.merge(overrides) do |_key, old_value, new_value|
            if old_value.is_a?(Hash) && new_value.is_a?(Hash)
              deep_merge_hash(old_value, new_value)
            else
              new_value
            end
          end
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

        def truthy?(value)
          case value
          when true
            true
          when false, nil
            false
          when String
            %w[true 1 yes on].include?(value.strip.downcase)
          else
            !!value
          end
        end
      end
    end
  end
end
