# frozen_string_literal: true

require 'async/http/endpoint'
require 'async/rest/representation'
require 'pp'

module EDMS
  # Parent namespace of all +mayan-edms+ models.
  module Mayan
    # Base class for all REST representations in +mayan-edms+.
    class Representation < Async::REST::Representation
      def related(klass, url)
        endpoint = Async::HTTP::Endpoint.parse(url)
        klass.new @resource.with(path: endpoint.path), metadata: metadata
      end

      def subresource(klass, attributes, url_key = :url)
        endpoint = Async::HTTP::Endpoint.parse(attributes[url_key])
        klass.new @resource.with(path: endpoint.path), metadata: metadata, value: attributes
      end
    end

    # Base class for a "paginated list" in +mayan-edms+.
    class Paginated < Representation
      include Enumerable

      def each(**parameters)
        return to_enum(:each, **parameters) unless block_given?

        pager = @resource.with(**parameters)
        while true
          page = pager.get(self.class)
          break if page.value[:count] == 0

          Array(page.value[:results]).each do |item|
            yield page.subresource(representation, item)
          end

          break if page.value[:next].nil?

          endpoint = Async::HTTP::Endpoint.parse(page.value[:next])
          pager = pager.class.new(pager.delegate,
                                  ::Protocol::HTTP::Reference.parse(endpoint.path),
                                  pager.headers.dup)
        end
      end

      def empty?
        value[:count] == 0
      end

      alias all to_a
    end

    # Main "client" class for REST representations in +mayan-edms+.
    class Client < Representation
      def cabinet(id)
        with Cabinet, path: "cabinets/#{id}/"
      end

      def document(id)
        with Document, path: "documents/#{id}/"
      end

      def document_type(id)
        with DocumentType, path: "document_types/#{id}/"
      end
    end

    # Represents a "cabinet" in +mayan-edms+.
    class Cabinet < Representation
      def documents
        with Documents, path: 'documents/'
      end
      def documents_add
        with Documents, path: 'documents/add/'
      end
    end

    # Represents "document pages" in +mayan-edms+.
    class Documents < Paginated
      def representation
        Document
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

      def tags
        with Tags, path: 'tags/'
      end

      def tags_attach
        with Tags, path: 'tags/attach/'
      end

      def files
        related DocumentFiles, value[:file_list_url]
      end

      def first_file
        files.first
      end

      def latest_version
        subresource DocumentVersion, value[:version_active]
      end

      def document_type
        subresource DocumentType, value[:document_type]
      end

      def document_metadata_map
        @document_metadata_map ||= document_metadata_map!
      end

      def document_metadata_map!(from = document_metadata)
        Hash[from.all.map { |r| [r.value[:metadata_type][:name], r] }]
      end
    end

    # Represents "document files" in +mayan-edms+.
    class DocumentFiles < Paginated
      def representation
        DocumentFile
      end
    end

    # Represents a "document file" in +mayan-edms+.
    class DocumentFile < Representation
      def pages
        related DocumentFilePages, value[:page_list_url]
      end

      def content
        pages.map(&:text_content).join("\n")
      end
    end

    # Represents "document pages" in +mayan-edms+.
    class DocumentFilePages < Paginated
      def representation
        DocumentFilePage
      end
    end

    # Represents a "document page" in +mayan-edms+.
    class DocumentFilePage < Representation
      def content
        with Representation, path: 'content/'
      end

      def text_content
        content.value[:content]
      end
    end

    # Represents a "document version" in +mayan-edms+.
    class DocumentVersion < Representation
      def pages
        related DocumentPages, value[:page_list_url]
      end

      def ocr_content
        pages.map(&:ocr_content).join("\n")
      end
    end

    # Represents "tags" in +mayan-edms+.
    class Tags < Paginated
      def representation
        Tag
      end
    end

    # Represents a "tag" in +mayan-edms+.
    class Tag < Representation
    end

    # Represents "document pages" in +mayan-edms+.
    class DocumentPages < Paginated
      def representation
        DocumentPage
      end
    end

    # Represents a "document page" in +mayan-edms+.
    class DocumentPage < Representation
      def ocr
        with Representation, path: 'ocr/'
      end

      def ocr_content
        ocr.value[:content]
      end
    end

    # Represents a list of "document metadata" in +mayan-edms+.
    class DocumentMetadatas < Paginated
      def representation
        DocumentMetadata
      end
    end

    # Represents "document metadata" in +mayan-edms+.
    class DocumentMetadata < Representation
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
        Hash[from.all.map { |r| r.value[:metadata_type].values_at(:name, :id) }]
      end
    end

    # Represents a list "metadata types" associated with "document types" in +mayan-edms+.
    class DocumentTypeMetadataTypes < Paginated # Representation
      def representation
        DocumentTypeMetadataType
      end
    end

    # Represents a list "metadata types" associated with "document types" in +mayan-edms+.
    class DocumentTypeMetadataType < Representation
    end
  end
end
