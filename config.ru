# frozen_string_literal: true

$LOAD_PATH << File.expand_path('lib', __dir__)
require 'edms/analyzer'

require 'rack/logger'
require 'rack/common_logger'
require 'securerandom'
require 'async'

class InternalLogger
  include EDMS::Analyzer::RackEnv

  def initialize(app)
    @unlogged = app
    @logged   = Rack::CommonLogger.new(app)
  end

  def should_log_request?(env)
    env['PATH_INFO'] != '/heartbeat'
  end

  def call(env)
    env[ASYNC_LOGGER_TOPIC] ||= SecureRandom.base64(9)
    env[ASYNC_LOGGER] = Async.logger.with(level: :info, name: "[web] #{env[ASYNC_LOGGER_TOPIC]}")

    Async(logger: env[ASYNC_LOGGER]) do
      (should_log_request?(env) ? @logged : @unlogged).call(env)
    end.wait
  end
end

use InternalLogger
use Rack::Logger

run EDMS::Analyzer::Web
