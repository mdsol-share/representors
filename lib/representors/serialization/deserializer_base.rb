require 'representors/serialization/serialization_base'
require 'representors/serialization/deserializer_factory'

module Representors
  class DeserializerBase < SerializationBase

    def self.inherited(subclass)
      DeserializerFactory.register_deserializers(subclass)
    end

    # Returns back a class with all the information of the document and with convenience methods
    # to access it.
    # TODO: Yield builder to factor out builder dependency.
    def to_representor
      Representor.new(to_representor_hash)
    end

    # Returns a hash representation of the data. This is useful to merge with new data which may
    # be built by different builders. In this class we use it to support embedded resources.
    def to_representor_hash(options = {})
      raise "Abstract method #to_representor_hash not implemented in #{self.name} deserializer class."
    end

  end
end
