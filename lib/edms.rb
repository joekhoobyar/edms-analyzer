# frozen_string_literal: true

require 'dry-types'
require 'ice_nine'
require 'ice_nine/core_ext/object'
require 'active_support/core_ext/object/blank'

# Parent namespace for EDMS analysis logic.
module EDMS
  # Default types for models.
  module Types
    include Dry.Types()

    ModelKey      = Types::Coercible::Integer
    MetadataKey   = Types::Coercible::String
    MetadataValue = Types::Any
    MetadataMap   = Types::Hash.map(MetadataKey, MetadataValue).default { {} }
  end

  autoload :Classifier, 'edms/classifier'
  autoload :Document, 'edms/document'
  autoload :Mayan, 'edms/mayan'
  autoload :MayanDecorator, 'edms/mayan_decorator'
  autoload :TextAnalyzer, 'edms/text_analyzer'
end
