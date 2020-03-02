# frozen_string_literal: true

require 'edms'

describe EDMS::MayanDecorator do
  let(:ctor_args) { [] }

  subject { EDMS::MayanDecorator.new(*ctor_args) }

  around :each do |example|
    keys = %w[MAYAN_EDMS_URL MAYAN_EDMS_USER MAYAN_EDMS_PASSWORD]
    values = keys.each { |key| ENV.delete(key) }
    begin
      example.run
    ensure
      ENV.update(Hash[keys.zip(values)])
    end
  end

  describe '#initialize' do
    CONN = { url: 'http://localhost', user: 'joe', password: 'schmoe' }.deep_freeze!

    describe 'with no arguments' do
      before :each do
        allow(ENV).to receive(:[]).with('MAYAN_EDMS_URL').and_return(CONN[:url])
        allow(ENV).to receive(:[]).with('MAYAN_EDMS_USER').and_return(CONN[:user])
        allow(ENV).to receive(:[]).with('MAYAN_EDMS_PASSWORD').and_return(CONN[:password])
      end

      it 'loads connection settings from environment variables' do
        expect(ENV).to receive(:[]).with('MAYAN_EDMS_URL')
        expect(ENV).to receive(:[]).with('MAYAN_EDMS_USER')
        expect(ENV).to receive(:[]).with('MAYAN_EDMS_PASSWORD')
        subject.connection
      end

      its(:connection) { should eq(CONN) }
      its(:connection) { should be_frozen }
    end

    describe 'with a connection argument' do
      let :ctor_args do
        [{ connection: { url: 'http://localhost', user: 'he', password: 'do' } }]
      end

      its(:connection) { should eq(ctor_args.first[:connection]) }
      its(:connection) { should be_frozen }
    end
  end

  describe '#decorate(document)' do
    let(:client) { instance_double('EDMS::Mayan::Client') }
    let(:mayan_document) { instance_double('EDMS::Mayan::Document') }
    let(:mayan_document_type) { instance_double('EDMS::Mayan::DocumentType') }
    let(:mayan_document_metadata) { instance_double('EDMS::Mayan::DocumentMetadata') }
    let(:mayan_document_metadatas) { instance_double('EDMS::Mayan::DocumentMetadatas') }

    before :each do
      allow(subject).to receive(:with_client).and_yield(client)
      allow(client).to receive(:document).and_return(mayan_document)
      allow(mayan_document_type).to receive(:metadata_type_map)
        .and_return('bar' => 1234)
      allow(mayan_document).to receive(:document_metadata).and_return(mayan_document_metadatas)
      allow(mayan_document).to receive(:document_type).and_return(mayan_document_type)
      allow(mayan_document).to receive(:document_metadata_map).and_return({})
      allow(mayan_document_metadata).to receive(:patch)
        .and_return(double('response', success?: true, close: nil))
      allow(mayan_document_metadatas).to receive(:post)
        .and_return(double('response', success?: true, close: nil))
    end

    describe 'without additional metadata' do
      let(:document) { EDMS::Document.new(id: 1, text: 'testing') }

      it 'loads the document from the backend' do
        expect(client).to receive(:document).with(document.id)
        subject.decorate(document)
      end

      it 'does not write any metadata' do
        expect(mayan_document).not_to receive(:document_metadata)
        expect(mayan_document).not_to receive(:document_metadata_map)
        expect(subject).not_to receive(:write_document_metadata)
        subject.decorate(document)
      end
    end

    describe 'with additional metadata' do
      let(:metadata) { { 'foo' => 'bar' } }
      let(:document) { EDMS::Document.new(id: 1, text: 'testing', metadata: metadata) }

      before :each do
        allow(mayan_document).to receive(:document_metadata).and_return(mayan_document_metadata)
        allow(mayan_document).to receive(:document_metadata_map)
          .and_return({'foo' => mayan_document_metadata})
      end

      it 'loads the document from the backend' do
        expect(client).to receive(:document).with(document.id).and_return(mayan_document)
        subject.decorate(document)
      end

      it 'writes the metadata' do
        expect(subject).to receive(:write_document_metadata)
          .with(mayan_document, 'foo', 'bar').and_call_original
        expect(mayan_document_metadata).to receive(:patch).with('value' => 'bar')
        subject.decorate(document)
      end
    end

    describe 'with brand new metadata' do
      let(:metadata) { { 'bar' => 'foo' } }
      let(:document) { EDMS::Document.new(id: 1, text: 'testing', metadata: metadata) }

      before :each do
        allow(mayan_document).to receive(:document_metadata_map).and_return({})
      end

      it 'loads the document from the backend' do
        expect(client).to receive(:document).with(document.id).and_return(mayan_document)
        subject.decorate(document)
      end

      it 'writes the metadata' do
        expect(subject).to receive(:write_document_metadata)
                             .with(mayan_document, 'bar', 'foo').and_call_original
        expect(mayan_document_metadatas).to receive(:post)
          .with('metadata_type_pk' => 1234, 'value' => 'foo')
        subject.decorate(document)
      end
    end
  end
end
