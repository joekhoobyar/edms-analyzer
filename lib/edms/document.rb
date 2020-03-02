# frozen_string_literal: true

require 'dry-struct'
require 'edms'

module EDMS
  # A simplistic representation of a document.
  class Document < Dry::Struct
    attribute :text, Types::String
    attribute :metadata, Types::MetadataMap
  end
end
