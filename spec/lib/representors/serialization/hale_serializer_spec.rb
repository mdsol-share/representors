require 'spec_helper'
require 'yaml'
require 'uri'

#TODO: This should only test functionality of this class and not repeat the file hal_spec
module Representors
  describe Serialization::HaleSerializer do
    before do
      @base_representor = {
        protocol: 'http',
        href: 'www.example.com/drds',
        id: 'drds',
        doc: 'doc'
      }
      @options = {}
    end

    subject(:serializer) { SerializerFactory.build(:hale_json, Representor.new(document)) }
    let(:result) {JSON.parse(serializer.to_media_type(@options))}

    shared_examples "a hale documents attributes" do |representor_hash, media|
      let(:document) { RepresentorHash.new(representor_hash).merge(@base_representor) }

      representor_hash[:attributes].each do |k, v|
        it "includes the document attribute #{k} and associated value" do
          expect(result[k]).to eq(v[:value])
        end
      end
    end

    shared_examples "a hale documents links" do |representor_hash, media|
      let(:document) { representor_hash.merge(@base_representor) }
      representor = Representor.new(representor_hash)

      representor.transitions.each do |item|
        it "includes the document transition #{item}" do
          expect(result["_links"][item[:rel]]['href']).to eq(item.templated_uri)
        end
      end

      representor.meta_links.each do |transition|
        it "includes meta link #{transition}" do
          expect(result["_links"][transition.rel.to_s]['href']).to eq(transition.templated_uri)
        end
      end
    end

    shared_examples "a hale documents embedded hale documents" do |representor_hash, media|
      let(:document) { representor_hash.merge(@base_representor) }

      representor_hash[:embedded].each do |embed_name, embed|
        embed[:attributes].each do |k, v|
          it "includes the document attribute #{k} and associated value" do
            expect(result["_embedded"][embed_name][k]).to eq(v[:value])
          end
        end
        embed[:transitions].each do |item|
          it "includes the document attribute #{item} and associated value" do
            expect(result["_embedded"][embed_name]["_links"][item[:rel]]['href']).to eq(item[:href])
          end
        end
      end
    end

    shared_examples "a hale documents embedded collection" do |representor_hash, media|
      let(:document) { representor_hash.merge(@base_representor) }

      representor_hash[:embedded].each do |embed_name, embeds|
        embeds.each_with_index do |embed, index|
          embed[:attributes].each do |k, v|
            it "includes the document attribute #{k} and associated value" do
              expect(result["_embedded"][embed_name][index][k]).to eq(v[:value])
            end
          end
          embed[:transitions].each do |item|
            it "includes the document attribute #{item} and associated value" do
              expect(result["_embedded"][embed_name][index]["_links"][item[:rel]]['href']).to eq(item[:href])
            end
          end
        end
      end
    end

    describe '#to_media_type' do
      context 'Document that is empty' do
        let(:document) { {} }

        it 'returns a hash with no attributes, links or embedded resources' do
          expect(result).to eq({})
        end
      end

      context 'Document with only self link' do
        representor_hash = begin
          {
            transitions: [{rel: 'self', href: "www.example.com/coffeebucks/"}]
          }
        end

        it_behaves_like 'a hale documents links', representor_hash, @options
      end
      
      context 'Document with only self and profile link' do
        representor_hash = begin
          {  
            links: {
              profile: 'http://www.example.com/drds/show/DRDs',
            },
            transitions: [{rel: 'self', href: "www.example.com/coffeebucks/"}]
          }
        end

        it_behaves_like 'a hale documents links', representor_hash, @options
      end
      
      context 'Document with GET link' do
        representor_hash = begin
          {  
            links: {
              profile: 'http://www.example.com/drds/show/DRDs',
            },
            transitions: [
              {rel: 'self', href: "www.example.com/coffeebucks/"},
              {rel: "next", href: "www.example.com/coffeebucks?page=2"},
              {
                rel: 'orders', 
                href: "www.example.com/coffeebucks",
                descriptors: {
                  "order_status" => {
                    scope: "href",
                    options: {
                      'list' => [
                        "pending_payment",
                        "preparing",
                        "fulfilled"
                    ],},
                    :validators => [
                      "in"
                    ],
                    cardinality: "multiple",
                  },
                  "page" => {
                    scope: "href",
                    type: "integer",
                    :validators => [
                      {"min" => 1},
                      {"max" => 2},
                    ],
                    value: 1
                  }
                }
              }
            ]
          }
        end

        it_behaves_like 'a hale documents links', representor_hash, @options
        let(:document) { representor_hash.merge(@base_representor) }
        it 'has the expected Hale output' do
          link_data = result["_links"]["orders"]["data"]
          expect(link_data["order_status"]["scope"]).to eq("href")
          expect(link_data["order_status"]["in"]).to eq(true)
          expect(link_data["order_status"]["multi"]).to eq(true)
          expect(link_data["order_status"]["options"]).to eq([
                        "pending_payment",
                        "preparing",
                        "fulfilled"
                    ])

          expect(link_data["page"]["scope"]).to eq("href")
          expect(link_data["page"]["type"]).to eq("integer")
          expect(link_data["page"]["min"]).to eq(1)
          expect(link_data["page"]["max"]).to eq(2)
          expect(link_data["page"]["value"]).to eq(1)
        end
      end

      context 'Document with POST link' do
        representor_hash = begin
          {  
            links: {
              profile: 'http://www.example.com/drds/show/DRDs',
            },
            transitions: [
              {rel: 'self', href: "www.example.com/coffeebucks/"},
              {
                rel: 'place_order',
                method: 'POST', 
                href: "www.example.com/coffeebucks/orders",
                descriptors: {
                  "drink_type" => {
                    options: {
                      'list' => [
                         "coffee",
                         "americano",
                         "latte",
                         "mocha",
                         "cappuccino",
                         "macchiato",
                         "espresso"
                    ],},
                    :validators => [
                      "in",
                      "required"
                    ],
                    cardinality: "multiple",
                  },
                  "iced" => {
                    type: "boolean",
                    value: false
                  },
                  "size" => {
                    type: "integer",
                    field_type: "number",
                    options: {
                      'hash' => {
                            "small" => 8,
                            "medium" => 12,
                            "large" => 16,
                            "extra-large" => 20
                    },},
                    :validators => [
                      "in",
                      "required"
                    ],
                  },
                  "shots" => {
                    type: "integer",
                    field_type: "range",
                    :validators => [
                      {"min" => 0},
                      {"max" => 16},
                    ],
                  },
                  "decaf" => {
                    type: "integer",
                    field_type: "range",
                    :validators => [
                      {"min" => 0},
                      {"max" => 16},
                    ],
                  }
                }
              }
            ]
          }
        end

        it_behaves_like 'a hale documents links', representor_hash, @options
        let(:document) { representor_hash.merge(@base_representor) }
        it 'has the expected Hale output' do
          link_data = result["_links"]["place_order"]["data"]
          expect(link_data["drink_type"]["in"]).to eq(true)
          expect(link_data["drink_type"]["required"]).to eq(true)
          expect(link_data["drink_type"]["options"]).to eq([
                         "coffee",
                         "americano",
                         "latte",
                         "mocha",
                         "cappuccino",
                         "macchiato",
                         "espresso"
                    ])
          
          expect(link_data["iced"]["type"]).to eq("boolean")
          expect(link_data["iced"]["value"]).to eq(false)

          expect(link_data["size"]["type"]).to eq("integer:number")
          expect(link_data["size"]["in"]).to eq(true)
          expect(link_data["size"]["required"]).to eq(true)
          expect(link_data["size"]["options"]).to eq([
                            {"small" => 8},
                            {"medium" => 12},
                            {"large" => 16},
                            {"extra-large" => 20}
                    ])
          
          expect(link_data["shots"]["type"]).to eq("integer:range")
          expect(link_data["shots"]["min"]).to eq(0)
          expect(link_data["shots"]["max"]).to eq(16)          
          
          expect(link_data["decaf"]["type"]).to eq("integer:range")
          expect(link_data["decaf"]["min"]).to eq(0)
          expect(link_data["decaf"]["max"]).to eq(16)            
        end
      end

      context 'Document with properties and links' do
        representor_hash = begin
          {
            attributes: {
              "count" => {value: 3},
              "total_count" => {value: 6},
            },
            transitions: [
              {rel: 'self', href: "www.example.com/coffeebucks/"},
              {rel: "next", href: "www.example.com/coffeebucks?page=2"},
              {
                rel: 'orders', 
                href: "www.example.com/coffeebucks",
                descriptors: {
                  "order_status" => {
                    scope: "href",
                    options: {
                      'list' => [
                        "pending_payment",
                        "preparing",
                        "fulfilled"
                    ],},
                    :validators => [
                      "in"
                    ],
                    cardinality: "multiple",
                  },
                  "page" => {
                    scope: "href",
                    type: "integer",
                    :validators => [
                      {"min" => 1},
                      {"max" => 2},
                    ],
                    value: 1
                  }
                }
              }
            ]
          }
        end

        it_behaves_like 'a hale documents attributes', representor_hash, @options
        it_behaves_like 'a hale documents links', representor_hash, @options
      end
      
      context 'Document with properties' do
        representor_hash = begin
          {
            attributes: {
              "count" => {value: 3},
              "total_count" => {value: 6},
            },
          }
        end

        it_behaves_like 'a hale documents attributes', representor_hash, @options
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

        it_behaves_like 'a hale documents attributes', representor_hash, @options
        it_behaves_like 'a hale documents links', representor_hash, @options
        it_behaves_like 'a hale documents embedded hale documents', representor_hash, @options
      end

      context 'Document with an embedded collection' do
        embedded = [{
          transitions: [
            {rel: "self", href: "www.example.com/coffeebucks/1"},
            {
              rel: 'fulfill',
              href: "www.example.com/coffeebucks/1",
              method: "PUT",
              descriptors: {
                "status" => {
                  value: "fulfilled",
                  validators: [
                    "required"
                  ],
                }
              }
            }
          ],
          attributes: {
            "status" => {value: "preparing"},
            "created" => {value: 12569537329},
            "drink_type" => {value: "latte"},
            "iced" => {value: "true"},
            "size" => {value: 8},
            "shots" => {value: 2},
            "decaf" => {value: 1}
          }
        },{
          transitions: [
            {rel: "self", href: "www.example.com/coffeebucks/2"},
          ],
          attributes: {
            "status" => {value: "fulfilled"},
            "created" => {value: 12569537312},
            "drink_type" => {value: "latte"},
            "iced" => {value: "true"},
            "size" => {value: 8},
            "shots" => {value: 2},
            "decaf" => {value: 1}
          }
        },{
          transitions: [
            {rel: "self", href: "www.example.com/coffeebucks/3"},
            {
              rel: "cancel",
              href: "www.example.com/coffeebucks/3",
              method: "DELETE"
            },
            {
              rel: 'prepare',
              href: "www.example.com/coffeebucks/3",
              method: "PUT",
              descriptors: {
                "status" => {
                  value: "preparing",
                  validators: [
                    "required"
                  ],
                },
                "paid" => {
                  value: 495,
                  validators: [
                    "required"
                  ],
                }
              }
            }
          ],
          attributes: {
            "status" => {value: "pending_payment"},
            "created" => {value: 12569534536},
            "drink_type" => {value: "latte"},
            "iced" => {value: "true"},
            "size" => {value: 8},
            "shots" => {value: 2},
            "decaf" => {value: 1},
            "cost" => {value: 495}
          }
        },]
        
        
        representor_hash = begin
          {
            embedded: {
              "order_list" => embedded
            }
          }
        end

        let(:embedded_transitions) { {transitions: [
              {:href=>"www.example.com/coffeebucks/1", :rel=>"order_list"},
              {:href=>"www.example.com/coffeebucks/2", :rel=>"order_list"},
              {:href=>"www.example.com/coffeebucks/3", :rel=>"order_list"}
            ]
          } 
        }

        it 'does not add embedded links if they already exist' do
          representor = Representor.new(representor_hash.merge(@base_representor).merge(embedded_transitions))
          serialized_hale = JSON.parse(Serialization::HaleSerializer.new(representor).to_media_type)
          expect(serialized_hale["_links"]["order_list"].count).to eq(3)
        end

        it_behaves_like 'a hale documents embedded collection', representor_hash, @options
      end

      context 'Document with an complex object' do
        representor_hash = begin
          {
            attributes: {
              "count" => {value: 3},
              "total_count" => {value: 6},
            },
          transitions: [{
            rel: 'multi_order',
            href: "www.example.com/coffeebucks/orders",
            request_encoding: "application/json",
            method: "POST",
            descriptors: {
              "multi_order" => {
                  value: true
              },
              "orders" => {
                  type: "object",
                  cardinality: "multiple",
                  descriptors: {
                    "drink_type" => {
                      options: {
                        'list' => [
                           "coffee",
                           "americano",
                           "latte",
                           "mocha",
                           "cappuccino",
                           "macchiato",
                           "espresso"
                      ],},
                      :validators => [
                        "in",
                        "required"
                      ],
                      cardinality: "multiple",
                    },
                    "iced" => {
                      type: "boolean",
                      value: false
                    },
                    "size" => {
                      type: "integer",
                      field_type: "number",
                      options: {
                        'hash' => {
                              "small" => 8,
                              "medium" => 12,
                              "large" => 16,
                              "extra-large" => 20
                      },},
                      :validators => [
                        "in",
                        "required"
                      ],
                    },
                    "shots" => {
                      type: "integer",
                      field_type: "range",
                      :validators => [
                        {"min" => 0},
                        {"max" => 16},
                      ],
                    },
                    "decaf" => {
                      type: "integer",
                      field_type: "range",
                      :validators => [
                        {"min" => 0},
                        {"max" => 16},
                      ],
                    }
                  }
              }
            }
            }]
          }
        end
        
        it_behaves_like 'a hale documents attributes', representor_hash, @options
        it_behaves_like 'a hale documents links', representor_hash, @options

        let(:document) { representor_hash.merge(@base_representor) }
        it 'has the expected Hale output' do
          link_data = result["_links"]["multi_order"]["data"]["orders"]["data"]
          expect(link_data["drink_type"]["in"]).to eq(true)
          expect(link_data["drink_type"]["required"]).to eq(true)
          expect(link_data["drink_type"]["options"]).to eq([
                         "coffee",
                         "americano",
                         "latte",
                         "mocha",
                         "cappuccino",
                         "macchiato",
                         "espresso"
                    ])
        
          expect(link_data["iced"]["type"]).to eq("boolean")
          expect(link_data["iced"]["value"]).to eq(false)

          expect(link_data["size"]["type"]).to eq("integer:number")
          expect(link_data["size"]["in"]).to eq(true)
          expect(link_data["size"]["required"]).to eq(true)
          expect(link_data["size"]["options"]).to eq([
                            {"small" => 8},
                            {"medium" => 12},
                            {"large" => 16},
                            {"extra-large" => 20}
                    ])
        
          expect(link_data["shots"]["type"]).to eq("integer:range")
          expect(link_data["shots"]["min"]).to eq(0)
          expect(link_data["shots"]["max"]).to eq(16)          
        
          expect(link_data["decaf"]["type"]).to eq("integer:range")
          expect(link_data["decaf"]["min"]).to eq(0)
          expect(link_data["decaf"]["max"]).to eq(16)            
        end
        
      end
      
      context 'Document has a link data objects' do
        representor_hash = begin
          {
            transitions: [
              {
              href: '/mike',
              rel: 'author',
              method: 'post',
              descriptors: {
                'name' => {
                  type: 'text',
                  scope: 'href',
                  value: 'Bob',
                  options: {'list' => ['Bob', 'Jane', 'Mike'], 'id' => 'names'},
                  validators: [ "required" ]
                  }
                }
              }
            ]
          }
        end

        let(:document) { representor_hash.merge(@base_representor) }
        let(:serialized_result) { JSON.parse(serializer.to_media_type) }

        after do
          expect(@result_element).to eq(@document_element)
        end

        it 'returns the correct link method' do
          @result_element = serialized_result["_links"]['author']['method']
          @document_element = document[:transitions].first[:method]
        end

        it 'returns the correct type keyword in link data' do
          @result_element = serialized_result["_links"]['author']['data']['name']['type']
          @document_element = document[:transitions].first[:descriptors]['name'][:type]
        end

        it 'returns the correct scope keyword in link data' do
          @result_element = serialized_result["_links"]['author']['data']['name']['scope']
          @document_element = document[:transitions].first[:descriptors]['name'][:scope]
        end

        it 'returns the correct value keyword in link data' do
          @result_element = serialized_result["_links"]['author']['data']['name']['value']
          @document_element = document[:transitions].first[:descriptors]['name'][:value]
        end

        it 'returns the correct datalists' do
          @result_element = serialized_result["_meta"]['names']
          @document_element = document[:transitions].first[:descriptors]['name'][:options]['list']
        end

        it 'properly references the datalists' do
          @result_element = serialized_result["_links"]['author']['data']['name']['options']['_ref']
          @document_element = ['names']
        end
      end
    end
  end
end
