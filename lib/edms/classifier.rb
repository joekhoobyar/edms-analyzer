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
        @metadata = Hash[metadata.map do |k, v|
          v = Regexp.new v, Regexp::IGNORECASE if v.is_a? String
          [k, v]
        end]
      end

      def match?(document)
        metadata.all? { |key, pattern| document.metadata[key].to_s =~ pattern } &&
          (text.nil? || document.text.match(text))
      end
    end

    # Can modify pattern matched capture data.
    class CaptureModifier < Dry::Struct
      attribute :ids, Types.Array(Types::Coercible::Integer)
      attribute :type, Types::Coercible::Symbol.enum(:sprintf)
      attribute :args, Types.Array(Types::Any).default(EMPTY_ARRAY)

      def call(value)
        send :"transform_#{type}", value
      end

      private

      def transform_sprintf(value)
        args[0] % [value]
      end
    end

    attr_reader :pattern, :modifiers, :action

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

    def initialize(pattern:, modifiers: [], action:)
      pattern = { text: pattern } unless pattern.is_a? Hash
      @pattern = DocumentPattern.new(**pattern.transform_keys(&:to_sym))
      @modifiers = modifiers.map { |mod| CaptureModifier.new(mod.to_h.transform_keys(&:to_sym)) }
      @action = if action.is_a? Hash
                  ->(doc, match) { doc.with_metadata(with_replacements(action, match)) }
                else
                  action
                end
    end

    # @param document [EDMS::Document]
    #   a representation of the document to classify
    # @return [EDMS::Document]
    #   either a newly classified document, or the original document
    def call(document)
      matchdata = pattern.match?(document)
      if matchdata
        @action.call(document, matchdata)
      else
        document
      end
    end

    private

    def with_replacements(metadata, matchdata = $LAST_MATCH_INFO)
      captures = Array(matchdata&.captures).inject({}) do |h, c|
        id = h.size + 1
        c = modifiers.inject(c) { |v,m| m.ids.include?(id) ? m.call(v) : v }
        h.update("\\#{id}" => c)
      end

      Hash[metadata.map do |key, value|
        [key, value.is_a?(String) ? value.gsub(/\\\d{1}/, captures) : value]
      end]
    end
  end
end
