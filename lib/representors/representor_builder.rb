require 'representor_support/utilities'
require 'representors/representor_hash'

module Representors

  ##
  # Builder has methods to abstract the construction of Representor objects
  # In the present implementation it will create a hash of a specific format to
  # Initialize the Representor with, this will create classess with it.
  class RepresentorBuilder
    include RepresentorSupport::Utilities

    HREF_KEY = :href
    DATA_KEY = :data

    def initialize(representor_hash = {})
      @representor_hash = RepresentorHash.new(representor_hash)
    end

    # Returns a hash usable by the representor class
    def to_representor_hash
      @representor_hash
    end

    # Adds an attribute to the Representor. We are creating a hash where the keys are the
    # names of the attributes
    def add_attribute(name, value, options={})
      new_representor_hash = RepresentorHash.new(deep_dup(@representor_hash.to_h))
      new_representor_hash.attributes[name] = options.merge({value: value})
      RepresentorBuilder.new(new_representor_hash)
    end

    # Adds a transition to the Representor, each transition is a hash of values
    # The transition collection is an Array
    def add_transition(rel, href, options={})
      new_representor_hash = RepresentorHash.new(deep_dup(@representor_hash.to_h))
      options = symbolize_keys(options)
      options.delete(:method) if options[:method] == Transition::DEFAULT_METHOD
      link_values = options.merge({href: href, rel: rel})

      if options[DATA_KEY]
        link_values[Transition::DESCRIPTORS_KEY] = link_values.delete(DATA_KEY)
      end

      new_representor_hash.transitions.push(link_values)
      RepresentorBuilder.new(new_representor_hash)
    end

    # Adds directly an array to our array of transitions
    def add_transition_array(rel, array_of_hashes)
      array_of_hashes.reduce(RepresentorBuilder.new(@representor_hash)) do |memo, transition|
        transition = symbolize_keys(transition)
        href = transition.delete(:href)
        memo = memo.add_transition(rel, href, transition)
      end
    end

    def add_embedded(name, embedded_resource)
      new_representor_hash = RepresentorHash.new(deep_dup(@representor_hash.to_h))
      new_representor_hash.embedded[name] = embedded_resource
      RepresentorBuilder.new(new_representor_hash)
    end
  end
end
