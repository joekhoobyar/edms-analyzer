# frozen_string_literal: true

require 'edms'

describe EDMS::Classifier do
  describe '#initialize' do
    let(:ctor_args) { [] }

    subject { EDMS::Classifier.new(*ctor_args) }

    describe 'with text as a pattern' do
      let(:ctor_args) { [{ pattern: Faker::Name.unique.name, action: {} }] }

      its(:pattern) { should be_a(EDMS::Classifier::DocumentPattern) }
      its('pattern.text') { should be_a(Regexp) }
    end

    describe 'with a regex as a pattern' do
      let(:ctor_args) { [{ pattern: /abc/, action: {} }] }

      its(:pattern) { should be_a(EDMS::Classifier::DocumentPattern) }
      its('pattern.text') { should eq(/abc/) }
    end

    describe 'with a Hash as a pattern' do
      let(:ctor_args) { [{ pattern: { text: 'abc', metadata: { foo: 'bar' } }, action: {} }] }

      its(:pattern) { should be_a(EDMS::Classifier::DocumentPattern) }
      its('pattern.text') { should eq(/abc/i) }
      its('pattern.metadata') { should eq(foo: /bar/i) }
    end
  end

  describe EDMS::Classifier::DocumentPattern do
    let(:ctor_args) { [] }

    subject { EDMS::Classifier::DocumentPattern.new(*ctor_args) }

    describe 'with no arguments' do
      its(:text) { should be_nil }
      its(:metadata) { should_not be_nil }
      its(:metadata) { should be_empty }

      it 'can match documents with any text' do
        1.upto(10) do
          document = EDMS::Document.new text: Faker::Name.unique.name
          expect(subject).to be_match(document)
        end
      end

      it 'can match documents with any metadata' do
        1.upto(10) do
          metadata = { Faker::Name.unique.name => Faker::Name.unique.name }
          document = EDMS::Document.new text: '', metadata: metadata
          expect(subject).to be_match(document)
        end
      end

      it 'can match documents with any text or metadata' do
        1.upto(10) do
          metadata = { Faker::Name.unique.name => Faker::Name.unique.name }
          document = EDMS::Document.new text: Faker::Name.unique.name, metadata: metadata
          expect(subject).to be_match(document)
        end
      end
    end

    describe 'with a text pattern' do
      let(:some_text) { Faker::Name.unique.name }
      let(:ctor_args) { [{ text: some_text }] }
      let(:good_doc) { EDMS::Document.new text: some_text }

      its(:text) { should eq(/#{some_text}/i) }
      its(:metadata) { should_not be_nil }
      its(:metadata) { should be_empty }
      its('metadata.values') { should all(be_a(Regexp)) }

      it 'only matches a document with the proper text' do
        expect(subject).to be_match(good_doc)
        1.upto(10) do
          document = EDMS::Document.new text: Faker::Name.unique.name
          expect(subject).not_to be_match(document)
        end
      end
    end

    describe 'with text and metadata patterns' do
      let(:some_text) { Faker::Name.unique.name }
      let(:some_metadata) { { Faker::Name.unique.name => Faker::Name.unique.name } }
      let(:ctor_args) { [{ text: some_text, metadata: some_metadata }] }
      let(:good_doc) { EDMS::Document.new text: some_text, metadata: some_metadata }

      its(:text) { should eq(/#{some_text}/i) }
      its(:metadata) { should_not be_nil }
      its(:metadata) { should_not be_empty }

      it 'only matches a document with the proper text and metadata' do
        expect(subject).to be_match(good_doc)
        1.upto(10) do
          document = EDMS::Document.new text: Faker::Name.unique.name,
                                        metadata: {
                                          Faker::Name.unique.name => Faker::Name.unique.name
                                        }
          expect(subject).not_to be_match(document)
        end
      end
    end
  end
end
