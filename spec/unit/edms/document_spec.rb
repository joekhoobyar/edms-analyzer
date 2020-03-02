# frozen_string_literal: true

require 'edms/document'

describe EDMS::Document do
  let(:document) { EDMS::Document.new(text: "Newco\nPlease pay by 3/1/2021\nsomebody@newco.com") }

  subject { document }

  its(:text) { should match(/Newco/) }
  its(:metadata) { should be_a(Hash) }
end
