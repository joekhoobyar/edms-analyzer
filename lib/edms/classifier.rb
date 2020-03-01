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
      @action = ->(data) { data.merge(action) } if action.is_a? Hash
    end

    def ===(text)
      @pattern === text # rubocop:disable Style/CaseEquality
    end

    def call(data)
      @action.call(data)
    end
  end
end
