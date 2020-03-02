# frozen_string_literal: true

require 'edms/analyzer'

describe EDMS::Analyzer::Web, roda: :app do
  describe '/analyses/documents/1' do
    before do
      post '/analyses/documents/1', { 'foo' => 'bar' }
    end

    its(:status) { is_expected.to eq(201) }
  end
end
