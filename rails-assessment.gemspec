require_relative "lib/rails/assessment/version"

Gem::Specification.new do |spec|
  spec.name        = "rails-assessment"
  spec.version     = Rails::Assessment::VERSION
  spec.authors     = [ "Hamed M" ]
  spec.email       = [ "hamed.mon+gems@gmail.com" ]
  spec.homepage    = "https://github.com/hmontazeri/rails-assessment"
  spec.summary     = "Headless, themable assessment engine for Rails."
  spec.description = "Rails::Assessment is a mountable Rails 8 engine that renders configurable, themeable assessments driven by YAML or Ruby DSL definitions."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.3"
end
