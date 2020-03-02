#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'async'
$LOAD_PATH << 'lib'
require 'edms'

analyzer = EDMS::TextAnalyzer.new classifiers: [
  ['Shanks Enterprises', { vendor_name: 'Shanks' }]
]
document = analyzer.call EDMS::Document.new(id: 16, type: 1, text: $stdin.read)

$stdout.puts document.inspect

Async do
  decorator = EDMS::MayanDecorator.new
  $stdout.puts decorator.decorate(document)
end
