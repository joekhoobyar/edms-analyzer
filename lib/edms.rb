# frozen_string_literal: true

require 'dry-types'

# Parent namespace for EDMS analysis logic.
module EDMS
  # Default types for models.
  module Types
    include Dry.Types()

    MetadataMap = Types::Hash.map(Types::String, Types::Any).default { {} }
  end

  autoload :Classifier, 'edms/classifier'
  autoload :Mayan, 'edms/mayan'
  autoload :MayanDecorator, 'edms/mayan_decorator'
  autoload :TextAnalyzer, 'edms/classifier'
end
