require 'representors/has_format_knowledge'
require 'representors/serialization_factory_base'

module Representors
  class SerializerFactory < SerializationFactoryBase
    def self.register_serializers(*serializers)
      register_serialization_classes(*serializers)
    end

    def self.registered_serializers
      registered_serialization_classes
    end
  end
end

