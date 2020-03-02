# frozen_string_literal: true

module EDMS
  # Simple class that can analyze text and apply classifications to a dataset.
  class Classifier
    # Can pattern match multiple fields in a document.
    class DocumentPattern
      attr_reader :metadata, :text

      def initialize(text: nil, metadata: {})
        text = Regexp.new text, Regexp::IGNORECASE if text.is_a? String
        @text = text
        @metadata = Hash[ metadata.map do |k,v|
          v = Regexp.new v, Regexp::IGNORECASE if v.is_a? String
          [k, v]
        end ]
      end

      def match?(document)
        metadata.all? { |key,pattern| document.metadata[key].to_s =~ pattern } &&
          (text.nil? || document.text =~ text)
      end
    end

    attr_reader :pattern, :action

    def self.[](spec)
      case spec
      when Hash
        new(**spec.transform_keys(&:to_sym))
      when EDMS::Classifier
        spec
      else
        raise ArgumentError, "expected Hash, EDMS::Classifier, got: #{spec.class}:#{spec.name}"
      end
    end

    def initialize(pattern:, action:)
      pattern = { text: pattern } unless pattern.is_a? Hash
      @pattern = DocumentPattern.new(**pattern)
      @action = action
      @action = ->(data) { data.with_metadata(action) } if action.is_a? Hash
    end

    # @param document [EDMS::Document]
    #   a representation of the document to classify
    # @return [EDMS::Document]
    #   either a newly classified document, or the original document
    def call(document)
      if pattern.match? document
        @action.call(document)
      else
        document
      end
    end
  end
end
