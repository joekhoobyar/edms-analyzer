# frozen_string_literal: true

module EDMS
  # Simple class that can analyze text and apply classifications to a dataset.
  class Classifier
    attr_accessor :pattern, :action

    def self.[](*args)
      if args.length >= 2
        new(*args)
      elsif args.first.is_a? EDMS::Classifier
        args.first
      else
        raise ArgumentError
      end
    end

    def initialize(pattern, action)
      pattern = Regexp.new Regexp.escape(pattern.to_s), Regexp::IGNORECASE if pattern.is_a? String
      @pattern = pattern
      @action = action
      @action = ->(data) { data.with_metadata(action) } if action.is_a? Hash
    end

    # @param document [EDMS::Document]
    #   a representation of the document to classify
    # @return [EDMS::Document]
    #   either a newly classified document, or the original document
    def call(document)
      if document.text =~ pattern
        @action.call(document)
      else
        document
      end
    end
  end
end
