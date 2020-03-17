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
      attribute  :type, Types::Coercible::Symbol.enum(:metadata, :sprintf, :tax_year, :next_day,
                                                      :month_number, :month_start, :month_end)
      attribute  :args, Types.Array(Types::Any).default(EMPTY_ARRAY)
      attribute? :from, Types::Integer | Types::String
      attribute? :to, Types::Integer

      def call(captures, metadata={})
        case from
        when Integer
          value = send :"transform_#{type}", captures["\\#{from}"]
          captures["\\#{from || to}"] = value
        when String
          value = send :"transform_#{type}", from.gsub(/\\\d{1}/, captures)
          captures["\\#{to}"] = value
        when NilClass
          value = send :"transform_#{type}", metadata
          captures["\\#{to}"] = value
        end
      end

      private

      def transform_metadata(metadata)
        metadata[args.first]
      end

      def transform_sprintf(value)
        value.sub!(/^0+([1-9])/, '\1') if value.is_a? String
        args[0] % [value]
      end

      def transform_tax_year(value)
        d = (Date.parse(value) << -1)
        Date.new(d.year, d.month, 1).year.to_s
      end

      def transform_month_number(value)
        name = value.to_s.capitalize
        number = Date::MONTHNAMES.index(name) || Date::ABBR_MONTHNAMES.index(name)
        '%02d' % [number + 1] if number
      end

      def transform_next_day(value)
        (Date.parse(value) + 1).strftime(args[0] || '%Y-%m-%d')
      end

      def transform_month_end(value)
        d = (Date.parse(value) << -1)
        (Date.new(d.year, d.month, 1) - 1).strftime(args[0] || '%Y-%m-%d')
      end

      def transform_month_start(value)
        d = Date.parse(value)
        Date.new(d.year, d.month, 1).strftime(args[0] || '%Y-%m-%d')
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
                  ->(doc, match) { doc.with_metadata(with_replacements(doc, action, match)) }
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

    def with_replacements(doc, metadata, matchdata = $LAST_MATCH_INFO)
      captures = Array(matchdata&.captures).inject({}) do |h, c|
        h.update("\\#{h.size + 1}" => c)
      end

      modifiers.each { |modifier| modifier.call(captures, doc.metadata) }

      Hash[metadata.map do |key, value|
        [key, value.is_a?(String) ? value.gsub(/\\\d{1}/, captures) : value]
      end]
    end
  end
end
