# frozen_string_literal: true

require 'json'
require 'roda'
require 'edms/text_analyzer'

module EDMS
  module Analyzer
    # REST microservice entry point
    class Web < Roda
      plugin :empty_root

      route do |r|
        response['Content-Type'] = 'application/json'

        r.on 'analyses' do
          r.post 'documents', :document_id do |document_id|
            response.status = 201
            { 'message' => "posting #{document_id}", 'result' => [] }.to_json
          end
        end
      end
    end
  end
end
