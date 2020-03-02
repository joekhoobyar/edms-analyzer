# frozen_string_literal: true

require 'edms/analyzer'

describe EDMS::Analyzer::Web, roda: :app do
  describe '/analyses/documents' do
    before do
      allow_any_instance_of(EDMS::MayanDecorator).to receive(:decorate) do |_decorator, doc|
        @document = doc
      end
    end

    describe 'with bad data POST-ed' do
      before do
        post '/analyses/documents', { 'foo' => 'bar' }
      end

      its(:status) { is_expected.to eq(422) }
    end

    describe 'with good data POST-ed' do
      before do
        post '/analyses/documents', { 'id' => 1, 'type' => 1, 'text' => 'foobar' }
      end

      its(:status) { is_expected.to eq(201) }

      describe 'the decorated document' do
        subject { @document }

        it { is_expected.to be_a(EDMS::Document) }
      end
    end
  end
end
