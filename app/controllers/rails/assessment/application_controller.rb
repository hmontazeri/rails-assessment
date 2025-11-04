module Rails
  module Assessment
    class ApplicationController < ActionController::Base
      layout "rails/assessment/application"

      protect_from_forgery with: :exception

      helper Rails::Assessment::ApplicationHelper
      helper Rails::Assessment::Theme::Helpers
    end
  end
end
