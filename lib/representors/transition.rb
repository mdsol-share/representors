module Representors
  ##
  # Manages the respresentation of link elements for hypermedia messages.
  class Transition
    REL_KEY = :rel
    HREF_KEY = :href
    LINKS_KEY = :links
    METHOD_KEY = :method
    DESCRIPTORS_KEY = :descriptors
    DEFAULT_METHOD = 'GET'
    PARAMETER_FIELDS = 'href'
    ATTRIBUTE_FIELDS = 'attribute'
    URL_TEMPLATE = "%s{?%s}"

    # @example
    #   hash =  {rel: "self", href: "http://example.org"}
    #   Transition.new(hash)
    # Must contain at least the property :href
    # @param [Hash] the abstract representor hash defining a transition
    def initialize(transition_hash)
      @transition_hash = transition_hash
    end

    # @return [String] so the user can 'puts' this object
    def to_s
      @transition_hash.inspect
    end

    # @return [Hash] useful in cucumber steps where the feature file provides a hash
    def to_hash
      Hash[@transition_hash.map{ |k, v| [k.to_s, v] }]
    end

    # @return [String] The name of the Relationship
    def rel
      retrieve(REL_KEY)
    end

    # @return [String] The URI for the object
    def uri
      #TODO we are splitting here in case the URL is already templated.  In the
      # future, this should be replaced with something like Addressable::Template,
      # as should templated_uri
      retrieve(HREF_KEY).split('{').first
    end

    # @param [String] key on the transitions hash to retrieve
    # @return [String] with the value of the key
    def [](key)
      retrieve(key)
    end

    # @param [String] key on the transitions hash to retrieve
    # @return [Bool] false if there is no key
    def has_key?(key)
      !retrieve(key).nil?
    end

    # TODO: Figure out how to scope differently
    # @return [String] The URI for the object templated against #parameters
    def templated_uri
      @templated_uri ||= if parameters.empty?
        uri
      else
        #TODO replace with something like Addressable::Template
        URL_TEMPLATE % [uri, parameters.map { |p| p.name }.join(",")]
      end
    end

    def templated?
      templated_uri != uri
    end

    # @return [Array] who's elements are all <Crichton:Transition> objects
    def meta_links
      meta_links ||= (retrieve(LINKS_KEY) || []).map do |link_key, link_href|
        Transition.new({rel: link_key, href: link_href})
      end
    end

    # @return [String] representing the Uniform Interface Method
    def interface_method
      retrieve(METHOD_KEY) || DEFAULT_METHOD
    end

    # The Parameters (i.e. GET variables)
    #
    # @return [Array] who's elements are all <Crichton:Field> objects
    def parameters
      @parameters ||= get_field_by_type(PARAMETER_FIELDS)
    end

    # The Parameters (i.e. POST variables)
    #
    # @return [Array] who's elements are all <Crichton:Field> objects
    def attributes
      @attributes ||= get_field_by_type(ATTRIBUTE_FIELDS)
    end
    
    # The Parameters (i.e. GET variables)
    #
    # @return [Array] who's elements are all <Crichton:Field> objects
    def descriptors
      @descriptions ||= (attributes + parameters)
    end

    private

    # accept retrieving keys by symbol or string
    def retrieve(key)
      @transition_hash[key.to_sym] || @transition_hash[key.to_s]
    end

    def descriptor_fields(hash)
      hash[DESCRIPTORS_KEY].map { |k, v| Field.new({k => v }) }
    end

    def filtered_fields(fields, scope)
      fields.select { |field| field.scope == scope }
    end

    def get_field_by_type(field_type)
      fields = @transition_hash.has_key?(DESCRIPTORS_KEY) ? descriptor_fields(@transition_hash) : []
      filtered_fields(fields, field_type)
    end
  end
end
