module Rails
  module Assessment
    module Theme
      class Resolver
        def initialize(configuration: Rails::Assessment.configuration)
          @configuration = configuration
        end

        def resolve(request: nil, overrides: nil)
          configuration.theme_for(request: request, override: overrides)
        end

        private

        attr_reader :configuration
      end
    end
  end
end
