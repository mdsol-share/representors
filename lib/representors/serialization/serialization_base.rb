require 'representor_support/utilities'

module Representors
  class SerializationBase
    include RepresentorSupport::Utilities

    attr_reader :target

    def initialize(target)
      @target = target
    end

    def self.media_symbols
      @media_symbols ||= Set.new
    end

    def self.media_types
      @media_types ||= Set.new
    end

    private
    def self.media_symbol(*symbol)
      @media_symbols = media_symbols | symbol
    end

    def self.media_type(*media)
      @media_types = media_types | media
    end

  end
end
