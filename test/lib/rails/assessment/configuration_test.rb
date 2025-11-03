require "test_helper"

module Rails
  module Assessment
    class MockRequest
      def initialize(params = {})
        @params = params
      end

      def params
        @params
      end

      def query_parameters
        @params
      end

      def request_parameters
        {}
      end

      def path_parameters
        {}
      end
    end

    class ConfigurationTest < ActiveSupport::TestCase
      test "resolves theme by param strategy" do
        configuration = Configuration.new
        configuration.theme_strategy = :param
        configuration.theme_param_key = :theme
        configuration.themes = { "dark" => { colors: { primary: "#000000" } } }

        request = MockRequest.new({ "theme" => "dark" })
        theme = configuration.theme_for(request: request)

        assert_equal "#000000", theme[:colors][:primary]
      end

      test "falls back to initializer theme when param missing" do
        configuration = Configuration.new
        configuration.theme[:colors][:primary] = "#123456"
        configuration.theme_strategy = :param
        configuration.themes = {}

        request = MockRequest.new({})
        theme = configuration.theme_for(request: request)

        assert_equal "#123456", theme[:colors][:primary]
      end

      test "merges overrides" do
        configuration = Configuration.new
        overrides = { colors: { primary: "#FF0000" } }
        theme = configuration.theme_for(request: nil, override: overrides)
        assert_equal "#FF0000", theme[:colors][:primary]
      end
    end
  end
end
