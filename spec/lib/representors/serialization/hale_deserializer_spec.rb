require 'spec_helper'

module Representors
  describe HaleDeserializer do
    it 'inherits from HalDeserializer' do
      expect(HaleDeserializer.class.ancestors.include? HalDeserializer)
    end

    it 'provides the media type application/vnd.hale+json' do
      expect(HaleDeserializer.media_types).to include('application/vnd.hale+json')
    end

    it 'provides the media symbol :hale' do
      expect(HaleDeserializer.media_symbols).to include(:hale)
    end

    describe "#to_representor" do
      it_behaves_like 'can create a representor from a hal document' do
        subject(:deserializer) {Representors::HaleDeserializer.new(document)}
      end

      context '_meta with properties and links' do
        subject(:deserializer) {Representors::HaleDeserializer.new(document)}
        let(:semantics) { { 'title' => 'The Neverending Story'}}
        let(:transition_rel) { 'author'}
        let(:transition_href) { '/mike'}
        let(:document) do
          {
            'title' => 'The Neverending Story',
            '_links' => {
              'author' => {'href' => '/mike'}
            },
            '_meta' => {
              'any' => { 'json' => 'thing'}
            }
          }
        end
        let(:semantics_field) {deserializer.to_representor.properties}
        let(:transitions_field) {deserializer.to_representor.transitions}
        let(:embedded_field) {deserializer.to_representor.embedded }

        it 'return a hash with all the attributes of the document' do
          expect(semantics_field).to eq(semantics)
        end
        it 'Create a transition with the link' do
          expect(transitions_field.size).to eq(1)
          expect(transitions_field.first.rel).to eq(transition_rel)
          expect(transitions_field.first.uri).to eq(transition_href)
        end
        it 'does not return any embedded resource' do
          expect(embedded_field).to be_empty
        end

      end

    end

  end
end
