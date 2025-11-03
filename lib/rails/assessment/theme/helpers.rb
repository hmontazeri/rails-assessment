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
      end
    end
  end
end
