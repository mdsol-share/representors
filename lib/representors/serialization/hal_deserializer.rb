require 'json'
require 'representors/serialization/deserializer_base'
require 'representors/errors'

module Representors
  ##
  # Deserializes the HAL format as specified in http://stateless.co/hal_specification.html
  # For examples of how this format looks like check the files under spec/fixtures/hal
  # TODO: support Curies http://www.w3.org/TR/2010/NOTE-curie-20101216/
  class HalDeserializer < DeserializerBase
    LINKS_KEY = '_links'
    EMBEDDED_KEY = '_embedded'
    CURIE_KEY = 'curies'
    HREF = 'href'

    media_symbol :hal
    media_type 'application/hal+json', 'application/json'

    # Can be initialized with a json document(string) or an already parsed hash.
    #
    # @param [String, Hash] target The target object to deserialize
    def initialize(target)
      # sets the target in the base class
      super(target.is_a?(Hash) ? target : JSON.parse(target)) #This may raise with a Json parse error which is ok
    end

    # Returns back a class with all the information of the document and with convenience methods
    # to access it.
    def to_representor
      Representor.new(to_hash)
    end

    # Returns a hash representation of the data. This is useful to merge with new data which may
    # be built by different builders. In this class we use it to support embedded resources.
    def to_hash
      builder = RepresentorBuilder.new
      builder_add_from_deserialized!(builder)
      builder.to_representor_hash
    end

    private

    def builder_add_from_deserialized!(builder)
      deserialize_properties!(builder)
      deserialize_links!(builder)
      deserialize_embedded!(builder)
    end

    # Properties are normal JSON keys in the HAL document. Create properties in the resulting object
    def deserialize_properties!(builder)
      # links and embedded are not properties but keywords of HAL, skipping them.
      target.keys.each do |property_name|
        if (property_name != LINKS_KEY) && (property_name != EMBEDDED_KEY)
          builder.add_attribute(property_name, target[property_name])
        end
      end
    end

    # links are under '_links' in the original document. Links always have a key (its name) but
    # the value can be a hash with its properties or an array with several links.
    def deserialize_links!(builder)
      links = target[LINKS_KEY] || {}
      links.each do |link_rel, link_values|
        raise(DeserializationError, 'CURIE support not implemented for HAL') if link_rel.eql?(CURIE_KEY)
        if link_values.is_a?(Array)
          if link_values.map{|link| link[HREF]}.any?(&:nil?)
            raise DeserializationError, 'All links must contain the href attribute'
          end
          builder.add_transition_array(link_rel, link_values)
        else
          href = link_values.delete(HREF)
          raise DeserializationError, 'All links must contain the href attribute' unless href
          builder.add_transition(link_rel, href, link_values )
        end
      end
    end

    # embedded resources are under '_embedded' in the original document, similarly to links they can
    # contain an array or a single embedded resource. An embedded resource is a full document so
    # we create a new HalDeserializer for each.
    def deserialize_embedded!(builder)
      embedded = target[EMBEDDED_KEY] || {}
      embedded.each do |name, value|
        if value.is_a?(Array)
          resources = value.map do |one_embedded_resource|
            HalDeserializer.new(one_embedded_resource).to_hash
          end
          builder.add_embedded(name, resources)
        else
          resource_hash = HalDeserializer.new(value).to_hash
          builder.add_embedded(name, resource_hash)
        end
      end
    end
  end
end