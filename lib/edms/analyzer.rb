# frozen_string_literal: true

require 'edms'

module EDMS
  # Parent namespace for the analyzer microservice.
  module Analyzer
    autoload :Web, 'edms/analyzer/web'
  end
end
