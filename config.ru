# frozen_string_literal: true

$LOAD_PATH << File.expand_path('lib', __dir__)
require 'edms/analyzer'

require 'rack/logger'
require 'rack/common_logger'
require 'securerandom'
require 'async'

class InternalLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    logger = Async.logger.with(level: :info, name: "[web] #{SecureRandom.base64(9)}")

    Async(logger: logger) do
      @app.call(env)
    end.wait
  end
end

use InternalLogger
use Rack::Logger
use Rack::CommonLogger

run EDMS::Analyzer::Web
