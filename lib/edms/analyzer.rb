# frozen_string_literal: true

require 'edms'

module EDMS
  # Parent namespace for the analyzer microservice.
  module Analyzer

    # Namespace holding rack env constants.
    module RackEnv
      ASYNC_LOGGER       = 'async.logger'
      ASYNC_LOGGER_TOPIC = 'async.logger.topic'
    end

    autoload :Web, 'edms/analyzer/web'
  end
end
