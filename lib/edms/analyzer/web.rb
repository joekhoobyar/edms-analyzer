# frozen_string_literal: true

require 'json'
require 'roda'
require 'edms/text_analyzer'

module EDMS
  module Analyzer
    # REST microservice entry point
    class Web < Roda
      plugin :empty_root
      plugin :json_parser
      plugin :symbol_status

      plugin :error_handler do |e|
        text = e.message
        case e
        when Dry::Struct::Error
          response.status = :unprocessable_entity
        else
          response.status = 400
        end
        text
      end

      route do |r|
        response['Content-Type'] = 'application/json'

        r.on 'analyses' do
          analyzer = EDMS::TextAnalyzer.new classifiers: [
            ['Shanks Enterprises', { vendor_name: 'Shanks' }]
          ]

          r.post 'documents' do
            decorator = MayanDecorator.new
            document = Document.new r.POST.transform_keys(&:to_sym)
            document = analyzer.call document
            decorator.decorate document
            response.status = 201
            { 'message' => "Classifying document ##{document.id}", 'result' => [] }.to_json
          end
        end
      end
    end
  end
end
