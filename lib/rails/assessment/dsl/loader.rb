require "date"
require "yaml"

module Rails
  module Assessment
    module DSL
      class Loader
        class << self
          def load_all!
            Rails::Assessment.registry.reset

            load_yaml_definitions
            load_ruby_definitions
          end

          def load_yaml_definitions
            assessment_files("yml").each do |path|
              definition_hash = safe_load_yaml(path)
              next if definition_hash.nil?

              definition_hash["slug"] ||= File.basename(path, ".yml")
              definition = Rails::Assessment::Definition.from_hash(definition_hash)
              Rails::Assessment.registry.register(definition)
            rescue StandardError => e
              warn "[rails-assessment] Failed to load #{path}: #{e.message}"
            end
          end

          def load_ruby_definitions
            assessment_files("rb").each do |path|
              load path
            rescue StandardError => e
              warn "[rails-assessment] Failed to evaluate #{path}: #{e.message}"
            end
          end

          def assessment_files(extension)
            Rails::Assessment.configuration.assessments_paths.flat_map do |root|
              next [] unless root && File.directory?(root)

              Dir.glob(root.join("**", "*.#{extension}")).sort
            end
          end

          def safe_load_yaml(path)
            content = File.read(path)
            YAML.safe_load(
              content,
              permitted_classes: [
                Date,
                Time,
                Symbol
              ],
              aliases: true
            )
          end
        end
      end
    end
  end
end
