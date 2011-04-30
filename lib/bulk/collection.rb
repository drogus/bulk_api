require 'active_support/core_ext/module/delegation'

module Bulk
  class Collection
    class Errors
      class NoSuchRecord < StandardError; end

      attr_reader :collection
      delegate :records, :to => :collection

      def initialize(collection)
        @collection = collection
      end

      def set(id, error)
        id = id.to_s
        raise NoSuchRecord unless collection.exists?(id)
        records[id][:error] = error
      end

      def get(id)
        id = id.to_s
        raise NoSuchRecord unless collection.exists?(id)
        records[id][:error]
      end

      def delete(id)
        id = id.to_s
        raise NoSuchRecord unless collection.exists?(id)
        records[id].delete(:error)
      end
    end

    include Enumerable

    def initialize
      @records = Hash.new {|hash, key| hash[key] = {} }
    end

    # Clear the records
    def clear
      records.clear
    end

    # Get record with given id
    def get(id)
      records[id.to_s][:record]
    end

    # Set record for a given id
    def set(id, record)
      records[id.to_s][:record] = record
    end

    # Remove record from collection
    def delete(id)
      records.delete(id.to_s)
    end

    # Get the collection length
    def length
      records.length
    end

    # Clear records on collection
    def clear
      records.clear
    end

    # Checks if collection is empty
    def empty?
      records.empty?
    end

    # Returns errors for the records
    def errors
      @errors ||= Errors.new(self)
    end

    alias_method :exists?, :get

    private
    attr_reader :records
  end
end
