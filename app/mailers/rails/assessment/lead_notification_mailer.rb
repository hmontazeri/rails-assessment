module Rails
  module Assessment
    class LeadNotificationMailer < ApplicationMailer
      def new_lead(response, notification_email)
        @response = response
        @user_email = response.answers.dig("lead", "email")
        @user_name = response.answers.dig("lead", "name")
        @assessment_slug = response.assessment_slug
        @score = response.score
        @result = response.result
        @tags = response.tags.join(", ")

        mail(to: notification_email, subject: "New Lead: #{@user_name || @user_email} from #{@assessment_slug}")
      end
    end
  end
end
