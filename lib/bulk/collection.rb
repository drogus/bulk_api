require 'active_support/core_ext/module/delegation'
require 'bulk/abstract_collection'

module Bulk
  class Collection < AbstractCollection
    class Error < Struct.new(:type, :data)
      def to_hash
        h = {:type => type}
        h[:data] = data if data
        h
      end
    end

    class Errors < AbstractCollection
      attr_reader :collection

      def initialize(collection)
        @collection = collection
        super()
      end

      def set(id, error, data = nil)
        super(id, Error.new(error, data))
      end
    end

    # Returns errors for the records
    def errors
      @errors ||= Errors.new(self)
    end

    def to_hash(name, options = {})
      only_ids = options[:only_ids]
      response = {}

      each do |id, record|
        next if errors.get(id)
        response[name] ||= []
        response[name] << if only_ids
          record.id
        else
          opts = options[:as_json_options] ? options[:as_json_options].dup : {}
          record.as_json(opts)
        end
      end

      errors.each do |id, error|
        response[:errors] ||= {name => {}}
        response[:errors][name][id] = error.to_hash
      end

      response
    end
  end
end
