#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'async'
$LOAD_PATH << 'lib'
require 'edms/analyzer'

analyzer = EDMS::TextAnalyzer.new classifiers: [
  ['Shanks Enterprises', { vendor_name: 'Shanks' }]
]
metadata = analyzer.call($stdin.read)

$stdout.puts metadata.to_json
$stdout.puts ''

Async do
  decorator = EDMS::MayanDecorator.new 1
  $stdout.puts decorator.metadata.inspect
  decorator.send :write_document_metadata, 12, :vendor_name, 'Shanks'
end
