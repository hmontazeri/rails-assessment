require "active_support"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/hash/deep_merge"
require "active_support/core_ext/object/try"
require "active_support/core_ext/string/inflections"

require "rails/assessment/version"
require "rails/assessment/configuration"
require "rails/assessment/definition"
require "rails/assessment/dsl/builder"
require "rails/assessment/dsl/loader"
require "rails/assessment/logic_engine"
require "rails/assessment/response_builder"
require "rails/assessment/theme/helpers"
require "rails/assessment/theme/resolver"
require "rails/assessment/engine"

module Rails
  module Assessment
    class << self
      delegate :configure, :configuration, to: :configurator
      delegate :register, :find, :all, :reset, to: :registry

      def define(slug, &block)
        builder = Rails::Assessment::DSL::Builder.new(slug, &block)
        registry.register(builder.definition)
      end

      def load!
        DSL::Loader.load_all!
      end

      def config
        configuration
      end

      def registry
        @registry ||= Registry.new
      end

      def configurator
        @configurator ||= Configurator.new
      end
    end

    class Configurator
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield configuration if block_given?
      end
    end

    class Registry
      def initialize
        @mutex = Mutex.new
        @definitions = {}
      end

      def register(definition)
        return unless definition&.slug

        @mutex.synchronize do
          @definitions[definition.slug] = definition
        end
      end

      def find(slug)
        return if slug.nil?

        @definitions[slug.to_s]
      end

      def all
        @definitions.values
      end

      def reset
        @mutex.synchronize { @definitions = {} }
      end
    end
  end
end
