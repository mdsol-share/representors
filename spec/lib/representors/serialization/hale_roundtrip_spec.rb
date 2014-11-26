require 'spec_helper'

module Representors

  describe 'Hale round trips' do
    after do
      deserialized_representor = HaleDeserializer.new(@file).to_representor
      serialized_hale = Serialization::HaleSerializer.new(deserialized_representor).to_media_type
      redeserialized_representor = HaleDeserializer.new(serialized_hale).to_representor
      reserialized_hale = Serialization::HaleSerializer.new(redeserialized_representor).to_media_type
      expect(JSON.parse(serialized_hale)).to eq(JSON.parse(reserialized_hale))
    end

    it 'round trips a simple document' do
      @file = File.read("#{SPEC_DIR}/support/basic-hale.json")
    end

    it 'round trips a complex document' do
      @file = File.read("#{SPEC_DIR}/fixtures/complex_hale_document.json")
    end

    Dir["#{SPEC_DIR}/fixtures/hale_spec_examples/*.json"].each do |path|
      it "round trips the hale spec #{path[/hale_spec_examples\/(.*?)\.json/, 1]} document" do
        @file = File.read(path)
      end
    end

    Dir["#{SPEC_DIR}/fixtures/hale_tutorial_examples/*.json"].each do |path|
      it "round trips the hale tutorial #{path[/hale_tutorial_examples\/(.*?)\.json/, 1]} document" do
        @file = File.read(path)
      end
    end
  end
end
