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

    def initialize(document_type_id, connection: DEFAULT_CONNECTION)
      @document_type_id = document_type_id
      @connection = connection
    end

    def metadata
      @metadata ||= metadata!
    end

    protected

    def metadata!
      with_client do |client|
        types = client.document_type(document_type_id).metadata_types
        result = types.results.map { |r| r[:metadata_type].values_at(:name, :id) }
        types.close
        Hash[result]
      end
    end

    def write_document_metadata(document_id, metadata_name, metadata_value)
      metadata_id = metadata[metadata_name.to_s]
      raise ArgumentError, "no such metadata named '#{metadata_name}'" if metadata_id.nil?

      with_client do |client|
        client.document(document_id).metadata(metadata_id).patch('value' => metadata_value).read
      end
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
