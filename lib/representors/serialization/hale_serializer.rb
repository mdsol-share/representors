require 'representors/serialization/hal_serializer'

module Representors
  module Serialization
    class HaleSerializer < HalSerializer
      media_symbol :hale_json
      media_type 'application/vnd.hale+json'

      SEMANTIC_TYPES = {
        select: "text", #No way in Crichton to distinguish [Int] and [String]
        search:"text",
        text: "text",
        boolean: "bool", #a Server should accept ?cat&dog or ?cat=cat&dog=dog
        number: "number",
        email: "text",
        tel: "text",
        datetime: "text",
        time: "text",
        date: "text",
        month: "text",
        week: "text",
        object: "object",
        :"datetime-local" => "text"
      }
      # This is public and returning a hash to be able to implement embedded resources
      # serialization
      # TODO: make this private and merge with to_media_type
      # The name is quite misleading,
      def to_hash(options ={})
        base_hash, links, embedded_hales = common_serialization(@target)
        meta = get_data_lists(@target)
        base_hash.merge!(meta).merge!(links).merge!(embedded_hales.(options))
        base_hash
      end


      # This is the main entry of this class. It returns a serialization of the data
      # in a given media type.
      def to_media_type(options = {})
        to_hash(options).to_json
      end

      private

      def get_data_lists(representor)
        meta = {}
        representor.datalists.each do |datalist|
          meta[datalist.id] = datalist.to_data
        end
        meta.empty? ? {} : {'_meta' => meta }
      end

      def elemental_renderer(etype)
        {
          type: ->(element) { render_type(element.field_type,element.type) if element.field_type || element.type },
          scope: ->(element) { element.scope unless element.scope == 'attribute' },
          value: ->(element) { element.value unless element.value.nil? },
          multi: ->(element) { true if element.cardinality == "multiple" },
          data: ->(element) { render_data_elements(element.descriptors) if element.type == 'object' },
        }[etype]
      end
      
      def get_data_validators(element)
        element.validators.reduce({}) do |results, validator| 
          results.merge( validator.is_a?(Hash) ? validator : {validator => true} )
        end
      end
      
      def get_data_properties(element)
        [:type, :scope, :value, :multi, :data].reduce({}) do |result, symbol|
          elemental = elemental_renderer(symbol).call(element) 
          result.merge( elemental.nil? ? {} : {symbol => elemental} )
        end
      end

      def get_data_element(element)
        options = if element.options.datalist?
          { '_ref' => [element.options.id] }
        elsif element.options.type == Representors::Options::HASH_TYPE
          element.options.to_hash.map { |option| Hash[*option] }
        else
          element.options.to_list
        end
        element_data = get_data_validators(element)
        elementals = get_data_properties(element)
        elementals[:options] = options unless options.empty?
        { element.name => element_data.merge(elementals) }
      end

      def render_data_elements(elements)
        elements.reduce({}) do |results, element|
          results.merge( get_data_element(element) )
        end
      end

      def build_links_for_this_media_type(transition)
        link = super(transition) #default Hal serialization
        # below add fields specific for Hale
        data_elements = render_data_elements(transition.descriptors)
        link[:data] = data_elements unless data_elements.empty?
        link[:method] = transition.interface_method unless transition.interface_method == Transition::DEFAULT_METHOD
        link
      end
      
      def render_type(field_type, type = SEMANTIC_TYPES[field_type.to_sym])
        field_type ? "#{type}:#{field_type}" : "#{type}"
      end
    end
  end
end
