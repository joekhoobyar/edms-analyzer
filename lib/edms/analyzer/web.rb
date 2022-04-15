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
            # Construct the document from the request.
            document = Document.new r.POST.transform_keys(&:to_sym)

            # Background task to analyze the document.
            Async do
              decorator = MayanDecorator.new

              # Retrieve the text if it doesn't exist yet.
              if document.text.blank?
                logger.info "Retrieving text for document ##{document.id}"

                # Try file content first, falling back on OCR.
                document = document.with_text(decorator.with_client do |client|
                  mayan_doc = client.document(document.id)
                  mayan_doc.first_file.content&.strip.presence || mayan_doc.latest_version.ocr_content&.strip
                end)
              end

              # If the text if present:  scrub, analyze, classify
              if document.text.present?
                # Scrub
                document = document.with_text(document.text.scrub.force_encoding('UTF-8').
                                              gsub(/[^[:ascii:]]/i, ' ').
                                              gsub(/[^[:alnum:][:punct:][:space:]]/i, ' ').
                                              strip)

                # Analyze the document text.
                logger.info "Analyzing document ##{document.id}"
                document = analyzer.call document

                # Classify the document in the background.
                logger.info "Classifying document ##{document.id}"
                decorator.decorate document

                logger.info "Done with ##{document.id}"
              else
                logger.error "Cannot classify empty text in document ##{document.id}"
              end
            end

            # Return the response.
            response.status = 201
            { 'message' => "Queueing document ##{document.id} for classification", 'result' => [] }
          end
        end
      end
    end
  end
end
