# frozen_string_literal: true

require 'edms/classifier'

module EDMS
  # Simple text analyzer that can classify text with an array of Classifier instances,
  # then apply classifications from all applicable Classifier instances, in order.
  class TextAnalyzer
    def initialize(classifiers: [])
      @classifiers = classifiers.map { |a| EDMS::Classifier[*a] }
    end

    def call(text, data = {})
      @classifiers
        .select { |classifier| classifier === text } # rubocop:disable Style/CaseEquality
        .inject(data) { |accum, classifier| classifier.call(accum) }
    end
  end
end
