require "test_helper"
require "tmpdir"
require "fileutils"

module Rails
  module Assessment
    class DslLoaderTest < ActiveSupport::TestCase
      def setup
        @original_paths = Rails::Assessment.configuration.assessments_paths
        @tmpdir = Dir.mktmpdir("assessments")
        Rails::Assessment.configuration.assessments_paths = [ Pathname.new(@tmpdir) ]
        Rails::Assessment.registry.reset
        FileUtils.rm_f(Dir.glob(File.join(@tmpdir, "*")))
      end

      def teardown
        Rails::Assessment.configuration.assessments_paths = @original_paths
        Rails::Assessment.registry.reset
        FileUtils.remove_entry(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
      end

      test "loads assessments from yaml" do
        File.write(File.join(@tmpdir, "example.yml"), <<~YAML)
          title: Example Assessment
          slug: example
          questions:
            - text: Are you ready?
              options:
                - text: "Yes"
                  tag: ready
                - text: "No"
                  tag: not_ready
          result_rules:
            - tags: [ready]
              text: "You are ready"
            - fallback: true
              text: "Almost there"
        YAML

        DSL::Loader.load_all!

        definition = Rails::Assessment.find("example")
        refute_nil definition
        assert_equal "Example Assessment", definition.title
        assert_equal 1, definition.questions.size
        assert_equal %w[ready not_ready], definition.questions.first.options.map(&:tag)
      end

      test "loads ruby dsl definitions" do
        File.write(File.join(@tmpdir, "example.rb"), <<~RUBY)
          Rails::Assessment.define "dsl-assessment" do
            title "DSL Assessment"
            question "Favourite color?" do
              option "Blue", tag: :blue
              option "Red", tag: :red
            end
            result_rule "Blue wins" do
              tags :blue
            end
            fallback "No match"
          end
        RUBY

        DSL::Loader.load_all!

        definition = Rails::Assessment.find("dsl-assessment")
        refute_nil definition
        assert_equal "DSL Assessment", definition.title
        assert_equal 1, definition.questions.size
        assert_equal %w[blue red], definition.questions.first.options.map(&:tag)
      end
    end
  end
end
