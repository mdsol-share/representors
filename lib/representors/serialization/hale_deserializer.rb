require 'representor_support/utilities'
require 'representors/serialization/hal_deserializer'

module Representors
  # Class for a Hale document deserializer.
  # Built against Hale version 0.0.1, https://github.com/mdsol/hale/tree/0-0-stable
  # @since 0.0.2
  class HaleDeserializer < HalDeserializer
    media_symbol :hale
    media_type 'application/vnd.hale+json'

    META_KEY = '_meta'.freeze
    REF_KEY = '_ref'.freeze
    DATA_KEY = 'data'.freeze
    OPTIONS_KEY = 'options'.freeze
    RESERVED_KEYS = HalDeserializer::RESERVED_KEYS +  [META_KEY, REF_KEY]
    RESERVED_FIELD_VALUES = Field::SIMPLE_METHODS + [Field::NAME_KEY, Field::SCOPE_KEY, Field::OPTIONS_KEY, Field::VALIDATORS_KEY, Field::DESCRIPTORS_KEY, DATA_KEY]

    #TODO Make this not terrible (refactor hal deserializer to inherit from hale deserializer)
    # move all logic here
    def builder_add_from_deserialized(builder, media)
      media = dereference_meta_media(media)
      super    
    end

    def deserialize_links(builder, media)
      (media[LINKS_KEY] || {}).each do |link_rel, link_values|
        link_values = [link_values] unless link_values.is_a?(Array)
        ensure_valid_links!(link_rel, link_values)
        link_values = parse_validators(link_values)
        link_values = parse_options(link_values)
        builder = builder.add_transition_array(link_rel, link_values)
      end
      builder
    end

    private

    def ensure_valid_links!(link_rel, link_values_array)
      raise(DeserializationError, 'CURIE support not implemented for HAL') if link_rel.eql?(CURIE_KEY)

      if link_values_array.map { |link| link[HREF] }.any?(&:nil?)
        raise DeserializationError, 'All links must contain the href attribute'
      end
    end

    def deep_find_and_transform!(obj, target_key, &blk)
      if obj.respond_to?(:key) && obj.key?(target_key)
        deep_find_and_transform!(obj[target_key], target_key, &blk)
        yield obj
      elsif [Array, Hash].include?(obj.class)
        obj.each { |*el| deep_find_and_transform!(el.last, target_key, &blk) }
      end
    end

    def dereference_meta_media(media)
      media = deep_dup(media)
      # Remove _meta from media to prevent serialization as property
      if meta_info = media.delete(META_KEY)
        deep_find_and_transform!(media, REF_KEY) do |media|
          media.delete(REF_KEY).each { |ref| media[ref] = meta_info[ref] }
        end
      end
      media
    end

    def parse_options(media)
      media = deep_dup(media)
      deep_find_and_transform!(media, OPTIONS_KEY) { |media| parse_options!(media) }
      media
    end

    def parse_options!(media)
      if media[OPTIONS_KEY].is_a?(Array) && media[OPTIONS_KEY].first.is_a?(Hash)
        new_options = media[OPTIONS_KEY].reduce({}) { |memo, hash| memo.merge!(hash) }
        media[OPTIONS_KEY] = { 'hash' => new_options }
      elsif !media[OPTIONS_KEY].is_a?(Hash)
        media[OPTIONS_KEY] = { 'list' => deep_dup(media[OPTIONS_KEY]) }
      end
    end

    def parse_validators(media)
      media = deep_dup(media)
      deep_find_and_transform!(media, DATA_KEY) { |media| parse_data!(media) }
      media
    end

    def parse_data!(media)
      media[DATA_KEY].each do |field_key, field_value|
        arr = []
        field_value.each do |k,v|
          arr << {k => media[DATA_KEY][field_key].delete(k)} unless RESERVED_FIELD_VALUES.include?(k.to_sym)
        end
        media[DATA_KEY][field_key][Field::VALIDATORS_KEY] = arr unless arr.empty?
      end
    end

  end

end
