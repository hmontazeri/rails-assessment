class AddUuidToRailsAssessmentResponses < ActiveRecord::Migration[7.1]
  def up
    add_column :rails_assessment_responses, :uuid, :string
    add_index :rails_assessment_responses, :uuid, unique: true

    say_with_time "Backfilling response UUIDs" do
      require "securerandom"

      response_model = Class.new(ActiveRecord::Base) do
        self.table_name = "rails_assessment_responses"
      end

      response_model.reset_column_information
      response_model.where(uuid: nil).find_each(batch_size: 500) do |response|
        response.update_columns(uuid: SecureRandom.uuid)
      end
    end

    change_column_null :rails_assessment_responses, :uuid, false
  end

  def down
    remove_index :rails_assessment_responses, :uuid
    remove_column :rails_assessment_responses, :uuid
  end
end
