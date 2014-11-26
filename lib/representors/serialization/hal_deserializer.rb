require 'json'
require 'representors/serialization/deserializer_base'
require 'representors/errors'

module Representors
  ##
  # Deserializes the HAL format as specified in http://stateless.co/hal_specification.html
  # For examples of how this format looks like check the files under spec/fixtures/hal
  # TODO: support Curies http://www.w3.org/TR/2010/NOTE-curie-20101216/
  class HalDeserializer < DeserializerBase
    LINKS_KEY = '_links'.freeze
    EMBEDDED_KEY = '_embedded'.freeze
    CURIE_KEY = 'curies'.freeze
    HREF = 'href'.freeze
    RESERVED_KEYS = [LINKS_KEY, EMBEDDED_KEY]

    media_symbol :hal
    media_type 'application/hal+json', 'application/json'

    # This need to be public to support embedded data
    # TODO: make this private
    def to_representor_hash
      media = @target.is_a?(Hash) ? @target : JSON.parse(@target)
      builder_add_from_deserialized(RepresentorBuilder.new, media).to_representor_hash
    end

    private

    def builder_add_from_deserialized(builder, media)
      builder = deserialize_properties(builder, media)
      builder = deserialize_links(builder, media)
      builder = deserialize_embedded(builder, media)
    end

    # Properties are normal JSON keys in the HAL document. Create properties in the resulting object
    def deserialize_properties(builder, media)
      media.each do |k,v|
        builder = builder.add_attribute(k, v) unless (RESERVED_KEYS.include?(k))
      end
      builder
    end

    # links are under '_links' in the original document. Links always have a key (its name) but
    # the value can be a hash with its properties or an array with several links.
    def deserialize_links(builder, media)
      links = media[LINKS_KEY] || {}

      links.each do |link_rel,link_values|
        raise(DeserializationError, 'CURIE support not implemented for HAL') if link_rel.eql?(CURIE_KEY)
        if link_values.is_a?(Array)
          if link_values.map{|link| link[HREF]}.any?(&:nil?)
            raise DeserializationError, 'All links must contain the href attribute'
          end
          builder = builder.add_transition_array(link_rel, link_values)
        else
          href = link_values[HREF]
          raise DeserializationError, 'All links must contain the href attribute' unless href
          builder = builder.add_transition(link_rel, href, link_values )
        end
      end

      builder
    end

    # embedded resources are under '_embedded' in the original document, similarly to links they can
    # contain an array or a single embedded resource. An embedded resource is a full document so
    # we create a new HalDeserializer for each.
    def deserialize_embedded(builder, media)
      make_embedded_resource = ->(x) { self.class.new(x).to_representor_hash.to_h }
      (media[EMBEDDED_KEY] || {}).each do |name, value|
        resource_hash = map_or_apply(make_embedded_resource, value)
        builder = builder.add_embedded(name, resource_hash)
      end
      builder
    end

  end
end
