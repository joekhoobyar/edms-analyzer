# frozen_string_literal: true

require 'base64'
require 'edms/mayan'

module EDMS
  # A class that knows how to "decorate" a document in +mayan-edms+.
  class MayanDecorator
    attr_reader :document_type_id, :connection

    DEFAULT_CONNECTION = {
      url: ENV['MAYAN_EDMS_URL'],
      user: ENV['MAYAN_EDMS_USER'],
      password: ENV['MAYAN_EDMS_PASSWORD']
    }.freeze

    def initialize(connection: DEFAULT_CONNECTION)
      @connection = connection
    end

    # @param document [EDMS::Document]
    #   the document to decorate with metadata
    # @return [Hash{String => Object}]
    #   the applied metadata
    def decorate(document)
      with_client do |client|
        document.metadata.each do |name, value|
          mayan_doc = client.document(document.id)
          write_document_metadata mayan_doc, name, value
        end
      end
    end

    protected

    def write_document_metadata(mayan_doc, metadata_name, metadata_value)
      metadata_name = metadata_name.to_s

      if (metadata = mayan_doc.document_metadata_map[metadata_name])
        response = metadata.patch('value' => metadata_value)
        raise Async::REST::ResponseError, response unless response.success?

      elsif (metadata_id = mayan_doc.document_type.metadata_type_map[metadata_name])
        response = mayan_doc.document_metadata.post 'metadata_type_pk' => metadata_id,
                                                    'value' => metadata_value
        raise Async::REST::ResponseError, response unless response.success?

      else
        raise ArgumentError, "no such metadata named '#{metadata_name}'"
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
      headers
    end
  end
end
