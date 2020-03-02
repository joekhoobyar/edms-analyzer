# frozen_string_literal: true

$LOAD_PATH << 'lib'

require 'rspec/its'
require 'rspec-roda'
require 'simplecov'
require 'simplecov-json'
require 'simplecov-rcov'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,
  SimpleCov::Formatter::RcovFormatter
]
SimpleCov.enable_coverage :branch
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/Gemfile*'
  add_filter '/Guardfile'
end

# Patch for SimpleCov > 0.18.0
unless SimpleCov::SourceFile.public_instance_methods.include? :coverage
  SimpleCov::SourceFile.send :alias_method, :coverage, :coverage_data
end

# Make RSpec always output color.
RSpec.configure do |config|
  config.tty = true
end
