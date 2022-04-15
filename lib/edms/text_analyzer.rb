# frozen_string_literal: true

require 'edms/classifier'

module EDMS
  # Simple text analyzer that can classify text with an array of Classifier instances,
  # then apply classifications from all applicable Classifier instances, in order.
  class TextAnalyzer
    def initialize(classifiers: [])
      @classifiers = classifiers.map { |a| EDMS::Classifier[a] }
    end

    # @param document [EDMS::Document]
    #   a representation of the document to classify
    # @return [EDMS::Document]
    #   either a newly classified document, or the unmodified original document
    def call(document)
      @classifiers.inject(document) do |accum, classifier|
        classifier.call(accum)
      end
    end
  end
end
