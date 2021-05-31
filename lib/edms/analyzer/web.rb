# frozen_string_literal: true

require 'json'
require 'yaml'
require 'dry-struct'
require 'roda'
require 'edms/text_analyzer'

module EDMS
  module Analyzer
    # REST microservice entry point
    class Web < Roda
      include RackEnv

      CONFIG_FILE = File.expand_path('../../../config.yml', __dir__)

      def load_config
        YAML.load_file CONFIG_FILE
      end

      plugin :empty_root
      plugin :json
      plugin :json_parser
      plugin :symbol_status

      plugin :error_handler do |e|
        text = e.message
        response.status = case e
                          when Dry::Struct::Error
                            :unprocessable_entity
                          else
                            400
                          end
        { 'message' => text, 'result' => nil, 'backtrace' => e.backtrace.join("\n") }
      end

      plugin :heartbeat

      route do |r|
        response['Content-Type'] = 'application/json'

        logger = Async.logger

        r.on 'analyses' do
          config = load_config

          analyzer = EDMS::TextAnalyzer.new(**config['edms']['text_analyzer'].transform_keys(&:to_sym))

          r.post 'documents' do
            document = Document.new r.POST.transform_keys(&:to_sym)
            document = analyzer.call document
            logger.info "Queuing document ##{document.id} for classification"

            Async do
              MayanDecorator.new.decorate document
              logger.info "Classified document ##{document.id}"
            end

            response.status = 201
            { 'message' => "Classifying document ##{document.id}", 'result' => [] }
          end
        end
      end
    end
  end
end
