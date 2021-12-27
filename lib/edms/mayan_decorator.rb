# frozen_string_literal: true

require 'base64'
require 'edms/mayan'

module EDMS
  # A class that knows how to "decorate" a document in +mayan-edms+.
  class MayanDecorator
    attr_reader :connection

    DEFAULT_CONNECTION = lambda do
      { url: ENV['MAYAN_EDMS_URL'],
        user: ENV['MAYAN_EDMS_USER'],
        password: ENV['MAYAN_EDMS_PASSWORD'] }
    end

    def logger
      Async.logger
    end

    def initialize(connection: DEFAULT_CONNECTION.call)
      @connection = connection.dup.deep_freeze!
    end

    # @param document [EDMS::Document]
    #   the document to decorate with metadata
    # @return [Hash{String => Object}]
    #   the applied metadata
    def decorate(document)
      with_client do |client|
        mayan_doc = client.document(document.id)
        document.metadata.each do |name, value|
          next unless name =~ /^[A-Za-z0-9]/
          write_document_metadata mayan_doc, name, value
        end

        filename = document.metadata['_suggested_filename']
        write_document_label mayan_doc, filename if filename

        doctype = document.metadata['_suggested_doctype']
        write_document_type mayan_doc, doctype if doctype

        tag_ids = document.metadata['_suggested_tags']
        Array(tag_ids).each do |tag_id|
          assign_document_tag mayan_doc, tag_id
        end

        cabinet_ids = document.metadata['_suggested_cabinets']
        Array(cabinet_ids).each do |cabinet_id|
          cabinet = client.cabinet(cabinet_id)
          assign_cabinet_document cabinet, mayan_doc
        end
      end
    end

    protected

    def assign_document_tag(mayan_doc, tag_id)
      logger.info "Tagging document ##{mayan_doc.value[:id]} => tag ##{tag_id}"
      handle_response do
        mayan_doc.tags_attach.post('tag' => tag_id)
      end
    end

    def assign_cabinet_document(cabinet, mayan_doc)
      logger.info "Assigning document ##{mayan_doc.value[:id]} => cabinet ##{cabinet.value[:id]}"
      handle_response do
        cabinet.documents_add.post('document' => mayan_doc.value[:id].to_s)
      end
    end

    def write_document_label(mayan_doc, filename)
      logger.info "Writing document ##{mayan_doc.value[:id]} => label ##{filename}"
      handle_response do
        mayan_doc.patch('label' => filename)
      end
    end

    def write_document_type(mayan_doc, doctype)
      logger.info "Writing document ##{mayan_doc.value[:id]} => type ##{doctype}"
      handle_response do
        mayan_doc.with(path: 'type/change/').post('document_type_id' => doctype)
      end
    end

    def write_document_metadata(mayan_doc, metadata_name, metadata_value)
      logger.info "Writing document ##{mayan_doc.value[:id]} metadata #{metadata_name} => #{metadata_value}"

      handle_response do
        metadata_name = metadata_name.to_s

        if (metadata = mayan_doc.document_metadata_map[metadata_name])
          metadata.patch('value' => metadata_value)
        elsif (metadata_id = mayan_doc.document_type.metadata_type_map[metadata_name])
          mayan_doc.document_metadata.post 'metadata_type_id' => metadata_id,
                                                      'value' => metadata_value
        else
          raise ArgumentError, "no such metadata key: #{metadata_name}"
        end
      end
    end

    private

    def handle_response
      response = yield
      raise Async::REST::ResponseError, response unless response.success?
    ensure
      response.close if response
    end

    def with_client(now: true)
      result = nil
      task = Mayan::Client.for "#{connection[:url]}/api/v4/", client_headers do |client|
        result = yield client
      end
      task.wait if now
      now ? result : task
    end

    def client_headers
      headers = Protocol::HTTP::Headers.new
      userpass = "#{connection[:user]}:#{connection[:password]}"
      headers['Authorization'] = "Basic #{Base64.encode64(userpass).chomp}"
      headers['Content-type'] = 'application/json'
      headers
    end
  end
end
