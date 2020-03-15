# frozen_string_literal: true

require 'async/http/endpoint'
require 'async/rest/representation'

module EDMS
  # Parent namespace of all +mayan-edms+ models.
  module Mayan
    # Base class for all REST representations in +mayan-edms+.
    class Representation < Async::REST::Representation
    end

    # Main "client" class for REST representations in +mayan-edms+.
    class Client < Representation
      def document(id)
        with Document, path: "documents/#{id}/"
      end

      def document_type(id)
        with DocumentType, path: "document_types/#{id}/"
      end
    end

    # Represents a "document" in +mayan-edms+.
    class Document < Representation
      def document_metadata(id = nil)
        if id.nil?
          with DocumentMetadatas, path: 'metadata/'
        else
          with DocumentMetadata, path: "metadata/#{id}/"
        end
      end

      def document_type
        endpoint = Async::HTTP::Endpoint.parse(value[:document_type][:url])
        DocumentType.new @resource.with(path: endpoint.path),
                         metadata: metadata,
                         value: value[:document_type]
      end

      def document_metadata_map
        @document_metadata_map ||= document_metadata_map!
      end

      def document_metadata_map!(from = document_metadata)
        Hash[from.results.map { |r| [r.value[:metadata_type][:name], r] }]
      end
    end

    # Represents "document metadata" in +mayan-edms+.
    class DocumentMetadata < Representation
    end

    # Represents a list of "document metadata" in +mayan-edms+.
    class DocumentMetadatas < Representation
      def results
        value[:results].map do |result|
          endpoint = Async::HTTP::Endpoint.parse(result[:url])
          DocumentMetadata.new @resource.with(path: endpoint.path),
                               metadata: metadata,
                               value: result
        end
      end
    end

    # Represents a "document type" in +mayan-edms+.
    class DocumentType < Representation
      def metadata_types
        with DocumentTypeMetadataTypes, path: 'metadata_types/'
      end

      def metadata_type_map
        @metadata_type_map ||= metadata_type_map!
      end

      def metadata_type_map!(from = metadata_types)
        Hash[from.results.map { |r| r[:metadata_type].values_at(:name, :id) }]
      end
    end

    # Represents a list "metadata types" associated with "document types" in +mayan-edms+.
    class DocumentTypeMetadataTypes < Representation
      def results
        value[:results]
      end
    end
  end
end
