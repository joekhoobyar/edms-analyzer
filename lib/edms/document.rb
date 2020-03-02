# frozen_string_literal: true

require 'dry-struct'
require 'edms'

module EDMS
  # A simplistic representation of a document.
  class Document < Dry::Struct
    attribute? :id,       Types::ModelKey
    attribute? :type,     Types::Any
    attribute  :text,     Types::String
    attribute  :metadata, Types::MetadataMap

    def with_metadata(new_metadata)
      self.class.new attributes.merge(metadata: metadata.merge(new_metadata))
    end
  end
end
