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
      end
    end

    protected

    def write_document_label(mayan_doc, filename)
      puts "Writing document ##{mayan_doc.value[:id]} => label ##{filename}"
      response = mayan_doc.patch('label' => filename)
      raise Async::REST::ResponseError, response unless response.success?
      response.close
    end

    def write_document_type(mayan_doc, doctype)
      puts "Writing document ##{mayan_doc.value[:id]} => type ##{doctype}"
      response = mayan_doc.with(path: 'type/change/').post('new_document_type' => doctype)
      raise Async::REST::ResponseError, response unless response.success?
      response.close
    end

    def write_document_metadata(mayan_doc, metadata_name, metadata_value)
      metadata_name = metadata_name.to_s
      puts "Writing document ##{mayan_doc.value[:id]} metadata #{metadata_name} => #{metadata_value}"

      if (metadata = mayan_doc.document_metadata_map[metadata_name])
        response = metadata.patch('value' => metadata_value)
        raise Async::REST::ResponseError, response unless response.success?

      elsif (metadata_id = mayan_doc.document_type.metadata_type_map[metadata_name])
        response = mayan_doc.document_metadata.post 'metadata_type_pk' => metadata_id,
                                                    'value' => metadata_value
        raise Async::REST::ResponseError, response unless response.success?

      else
        raise ArgumentError, "no such metadata key: #{metadata_name}"
      end

      response.close
    end

    private

    def with_client(now: true)
      result = nil
      task = Mayan::Client.for "#{connection[:url]}/api/", client_headers do |client|
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
