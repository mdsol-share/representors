require 'spec_helper'
require 'yaml'
require 'uri'

module Representors
  describe Serialization::HalSerializer do

    subject(:serializer) { SerializerFactory.build(:hal_json, Representor.new(document)) }
    let(:result) {JSON.parse(serializer.to_media_type)}
    let(:base_representor) do
      {
         protocol: 'http',
         href: 'www.example.com/drds',
         id: 'drds',
         doc: 'doc'
      }
    end

    shared_examples 'a hal documents attributes' do |representor_hash|
      let(:document) { representor_hash.merge(base_representor) }

      representor_hash[:attributes].each do |k, v|
        it "includes the document attribute #{k} and associated value" do
          expect(result[k]).to eq(v[:value])
        end
      end
    end

    shared_examples 'a hal documents links' do |representor_hash|
      let(:document) { representor_hash.merge(base_representor) }

      representor_hash[:transitions].each do |item|
        it "includes the document transition #{item}" do
          links = result['_links']
          link = links[item[:rel]]
          expect(link['href']).to eq(item[:href])
        end
      end
    end

    shared_examples 'a hal documents embedded hal documents' do |representor_hash|
      let(:document) { representor_hash.merge(base_representor) }

      representor_hash[:embedded].each do |embed_name, embed|
        embed[:attributes].each do |k, v|
          it "includes the document attribute #{k} and associated value" do
            expect(result['_embedded'][embed_name][k]).to eq(v[:value])
          end
        end
        embed[:transitions].each do |item|
          it "includes the document attribute #{item} and associated value" do
            expect(result['_embedded'][embed_name]['_links'][item[:rel]]['href']).to eq(item[:href])
          end
        end
      end
    end

    shared_examples 'a hal documents embedded collection' do |representor_hash|
      let(:document) { representor_hash.merge(base_representor) }

      representor_hash[:embedded].each do |embed_name, embeds|
        embeds.each_with_index do |embed, index|
          embed[:attributes].each do |k, v|
            it "includes the document attribute #{k} and associated value" do
              expect(result['_embedded'][embed_name][index][k]).to eq(v[:value])
            end
          end
          embed[:transitions].each do |item|
            it "includes the document attribute #{item} and associated value" do
              expect(result['_embedded'][embed_name][index]['_links'][item[:rel]]['href']).to eq(item[:href])
            end
          end
        end
      end
    end

    describe '#as_media_type' do
      context 'empty document' do
        let(:document) { {} }

        it 'returns a hash with no attributes, links or embedded resources' do
          empty_json_document = '{}'
          expect(serializer.to_media_type).to eq(empty_json_document)
        end
      end

      context 'Document with only properties' do
        representor_hash = begin
          {
            attributes: {
              'title' => {value: 'The Neverending Story'},
              'author' => {value: 'Michael Ende'},
              'pages' => {value: '396'}
            }
          }
        end

        it_behaves_like 'a hal documents attributes', representor_hash
      end

      context 'Document with properties and links' do
        representor_hash = begin
          {
            attributes: {
              'title' => {value: 'The Neverending Story'},
            },
            transitions: [
              {
                href: '/mike',
                rel: 'author',
              }
            ]
          }
        end

        it_behaves_like 'a hal documents attributes', representor_hash
        it_behaves_like 'a hal documents links', representor_hash
      end

      context 'Document with properties, links, and embedded' do
        representor_hash = begin
          {
            attributes: {
              'title' => {value: 'The Neverending Story'},
            },
            transitions: [
              {
                href: '/mike',
                rel: 'author',
              }
            ],
            embedded: {
              'embedded_book' => {attributes: {'content' => { value: 'A...' } }, transitions: [{rel: 'self', href: '/foo'}]}
            }
          }
        end

        it_behaves_like 'a hal documents attributes', representor_hash
        it_behaves_like 'a hal documents links', representor_hash
        it_behaves_like 'a hal documents embedded hal documents', representor_hash
      end

      context 'Document with an embedded collection' do
        representor_hash = begin
          {
            attributes: {
              'title' => {value: 'The Neverending Story'},
            },
            transitions: [
              {
                href: '/mike',
                rel: 'author',
              }
            ],
            embedded: {
              'embedded_book' => [
                {attributes: {'content' => { value: 'A...' } }, transitions: [{rel: 'self', href: '/foo1'}]},
                {attributes: {'content' => { value: 'B...' } }, transitions: [{rel: 'self', href: '/foo2'}]},
                {attributes: {'content' => { value: 'C...' } }, transitions: [{rel: 'self', href: '/foo3'}]}
              ]
            }
          }
        end

        it_behaves_like 'a hal documents attributes', representor_hash
        it_behaves_like 'a hal documents links', representor_hash
        it_behaves_like 'a hal documents embedded collection', representor_hash
      end
    end
  end
end
