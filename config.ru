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
    @app = app
  end

  def call(env)
    env[ASYNC_LOGGER_TOPIC] ||= SecureRandom.base64(9)
    env[ASYNC_LOGGER] = Async.logger.with(level: :info, name: "[web] #{env[ASYNC_LOGGER_TOPIC]}")

    Async(logger: env[ASYNC_LOGGER]) do
      @app.call(env)
    end.wait
  end
end

use InternalLogger
use Rack::Logger
use Rack::CommonLogger

run EDMS::Analyzer::Web
