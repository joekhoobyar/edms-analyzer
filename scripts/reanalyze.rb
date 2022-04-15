#!/usr/bin/env bundle exec ruby
# frozen_string_literal: true

require 'pp'
require 'json'
require 'async'
require 'async/http/internet'

$LOAD_PATH << File.expand_path('../lib', __dir__)
require 'edms/analyzer'

Async do
	internet = Async::HTTP::Internet.new
	headers = [['content-type', 'application/json; charset=UTF-8']]

  EDMS::MayanDecorator.new.with_client do |client|

    ARGV.each do |id|
      puts "retrieving document ##{id}"

      mayan_doc = client.document(id)
      body = {
        id: mayan_doc.value[:id],
        type: mayan_doc.value[:document_type][:id],
      }

      body[:text] = mayan_doc.first_file.content
      body[:text] = mayan_doc.latest_version.ocr_content if (body[:text]&.strip&.length || 0) == 0

      body[:text] = body[:text].
        scrub.
        force_encoding('UTF-8').
        gsub(/[^[:ascii:]]/i, ' ').
        gsub(/[^[:alnum:][:punct:][:space:]]/i, ' ').
        gsub(/[[:space:]]/i, ' ').
        strip

      puts "reanalyzing document ##{id}"
      url = ENV.fetch('ANALYZER_URL', 'http://localhost:9292/analyses/documents')
      response = internet.post(url, headers, body.to_json)
      pp JSON.parse(response.read)
    end

  end
ensure
  internet.close
end
