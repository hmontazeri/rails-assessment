class CreateRailsAssessmentResponses < ActiveRecord::Migration[7.1]
  def change
    create_table :rails_assessment_responses do |t|
      t.string :assessment_slug, null: false

      json_column = connection.adapter_name.to_s.downcase.include?("postgres") ? :jsonb : :json
      t.send(json_column, :answers, default: {})

      t.string :result

      t.timestamps
    end

    add_index :rails_assessment_responses, :assessment_slug
    add_index :rails_assessment_responses, :created_at
  end
end
