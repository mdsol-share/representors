module RepresentorSupport
  module Utilities

    # Accepts a hash and returns a new hash with symbolized keys
    def symbolize_keys(hash)
      Hash[hash.map{|(k,v)| [k.to_sym,v]}]
    end

    # Will recursively deep dup an aribitrary set of nested hashes and arrays,
    # but does not handle complex objects.  Also, this benchmarked *way* faster
    # than the Marshal approach.
    def deep_dup(obj)
      if obj.is_a?(Hash)
        result = {}
        obj.each { |k,v| result[k] = deep_dup(v) }
        result
      elsif obj.is_a?(Array)
        obj.map { |el| deep_dup(el) }
      else
        dup_or_self(obj)
      end
    end

    # Unfortunately the best way to test if you can actually dup an object is to
    # try, and handle the TypeError if not succesful.
    def dup_or_self(obj)
      begin
        obj.dup
      rescue TypeError
        obj
      end
    end

    def map_or_apply(proc, obj)
      obj.is_a?(Array) ? obj.map { |sub| proc.(sub) } : proc.(obj)
    end

  end
end