module Rails
  module Assessment
    class Engine < ::Rails::Engine
      isolate_namespace Rails::Assessment

      initializer "rails_assessment.asset_paths" do |app|
        app.config.assets.paths << root.join("app", "assets", "javascripts")
        app.config.assets.paths << root.join("app", "assets", "stylesheets")
        app.config.assets.paths << root.join("app", "assets", "images")
      end

      initializer "rails_assessment.assets.precompile" do |app|
        app.config.assets.precompile += %w[
          rails/assessment/theme.css
          rails/assessment/controllers/assessment_controller.js
        ]
      end

      initializer "rails_assessment.helpers" do
        ActiveSupport.on_load(:action_view) do
          include Rails::Assessment::Theme::Helpers
        end
      end

      config.to_prepare do
        Rails::Assessment.load! unless Rails::Assessment.configuration.cache_enabled
      end

      config.after_initialize do
        Rails::Assessment.load! if Rails::Assessment.configuration.cache_enabled
      end
    end
  end
end
