require 'yaml'
require 'enumerable/lazy' if RUBY_VERSION < '2.0'
require 'representors/field'
require 'representors/transition'
require 'representors/serialization/serializer_factory'

module Representors
  ##
  # Manages the respresentation of hypermedia messages for different media-types.
  class Representor
    DEFAULT_PROTOCOL = 'http'
    PROTOCOL_TEMPLATE = "%s://%s"
    UNKNOWN_PROTOCOL = 'ruby_id'
    VALUE_KEY = :value
    META_LINK_FIELDS = ['profile', 'help', 'type', 'self']

    # @example
    #  representor = Representors::Representor.new do |builder|
    #    builder.add_attribute({ name: => 'Bob' })
    #  end
    #
    # @param [Hash] hash the abstract representor hash defining a resource
    def initialize(hash = {}, builder = nil)
      builder ||= RepresentorBuilder.new(hash)
      builder = yield builder if block_given?
      @representor_hash = builder.to_representor_hash
    end

    # @param format to convert this representor to
    # @return the representor serialized to a particular media-type like application/hal+json
    def to_media_type(format, options={})
      SerializerFactory.build(format, self).to_media_type(options)
    end

    # Returns the document for the representor
    #
    # @return [String] the document for the representor
    def doc
      @doc ||= @representor_hash.doc || ''
    end

    # The URI for the object
    #
    # @note If the URI can't be made from the provided information it constructs one from the Ruby ID
    # @return [String]
    def identifier
      @identifier ||= begin
        uri = @representor_hash.href || self.object_id
        protocol = @representor_hash.protocol || (uri == self.object_id ? UNKNOWN_PROTOCOL : DEFAULT_PROTOCOL)
        PROTOCOL_TEMPLATE % [protocol, uri]
      end
    end

    # @return [Hash] The hash representation of the object
    def to_hash
      @to_hash ||= @representor_hash.to_h
    end

    # @return [String] the yaml representation of the object
    def to_yaml
      @to_yaml ||= YAML.dump(to_hash)
    end

    # @return [String] so the user can 'puts' this object
    def to_s
      to_hash.inspect
    end

    # @return [Hash] the resource attributes inferred from representor[:semantics]
    def properties
      @properties ||= Hash[@representor_hash.attributes.map { |k, v| [ k, v[VALUE_KEY]] }]
    end

    # @return [Enumerable] who's elements are all <Representors:Representor> objects
    def embedded
      @embedded ||= begin
        embedded_representors = @representor_hash.embedded.map do |name, values|
          if values.is_a?(Array)
            several_representors = values.map do |value|
              Representor.new(value)
            end
            [name, several_representors]
          else
            [name, Representor.new(values)]
          end
        end
        Hash[embedded_representors]
      end
    end

    # @return [Array] who's elements are all <Representors:Transition> objects
    def meta_links
      @meta_links ||= begin
        links_from_transitions = {}

        transitions.each do |transition|
          if META_LINK_FIELDS.include?(transition.rel)
            links_from_transitions[transition.rel.to_sym] = transition.uri
          end
        end

        @representor_hash.links.merge(links_from_transitions).map do |k, v|
          Representors::Transition.new({rel: k, href: v})
        end.uniq { |transition| [transition.rel, transition.uri] }
      end
    end

    # @return [Array] who's elements are all <Representors:Transition> objects
    def transitions
      @transitions ||= begin
        transition_hashes = (@representor_hash.transitions + embedded_transitions_hashes).uniq do |hash|
          [hash[:rel], hash[:href]]
        end
        transition_hashes.map { |hash| Transition.new(hash) }
      end
    end

   # @return [Array] who's elements are all <Representors:Transition> objects from the self links of
   # embedded items, updating the rel to reflect the embedded items key
    def embedded_transitions
      embedded_transitions_hashes.map { |hash| Transition.new(hash) }
    end

    # @return [Array] who's elements are all <Representors:Option> objects
    def datalists
      @datalists ||= begin
        attributes = transitions.map { |transition| transition.attributes }
        parameters = transitions.map { |transition| transition.parameters }
        fields = [attributes, parameters].flatten
        options = fields.map { |field| field.options }
        options.select { |o| o.datalist? }
      end
    end

    private

    def embedded_transitions_hashes
      @representor_hash.embedded.flat_map do |k,*v|
        v.flatten.map do |item|
          trans_hash = item[:transitions].find { |t| t[:rel] == "self" }
          if trans_hash
            profile_href = item[:links]["profile"] if item[:links]
            trans_hash = trans_hash.merge(profile: profile_href) if profile_href
            trans_hash.merge(rel: k)
          else
            {}
          end
        end
      end
    end


  end
end
