require "securerandom"

module Rails
  module Assessment
    class Response < ApplicationRecord
      self.table_name = "rails_assessment_responses"

      before_validation :ensure_uuid, on: :create

      store_accessor :answers if respond_to?(:store_accessor)

      validates :assessment_slug, presence: true
      validates :uuid, presence: true, uniqueness: true

      scope :for_assessment, ->(slug) { where(assessment_slug: slug.to_s) }

      def tags
        return [] unless answers.is_a?(Hash)

        answers.values.flat_map do |entry|
          case entry
          when Hash
            Array(entry["tags"] || entry[:tags])
          else
            Array(entry)
          end
        end.compact.map(&:to_s).uniq
      end

      def score
        return 0 unless answers.is_a?(Hash)

        answers.values.sum do |entry|
          case entry
          when Hash
            entry["score"] || entry[:score] || 0
          else
            0
          end
        end.to_i
      end

      private

      def ensure_uuid
        self.uuid ||= SecureRandom.uuid
      end
    end
  end
end
