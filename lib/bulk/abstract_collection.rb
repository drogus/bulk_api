module Bulk
  class AbstractCollection
    include Enumerable

    def initialize
      @items = {}
    end

    # Clear items
    def clear
      items.clear
    end

    # Get record with given id
    def get(id)
      items[id.to_s]
    end
    alias_method :exists?, :get

    # Set record for a given id
    def set(id, item)
      items[id.to_s] = item
    end

    # Remove record from collection
    def delete(id)
      items.delete(id.to_s)
    end

    # Get the collection length
    def length
      items.length
    end

    # Clear records on collection
    def clear
      items.clear
    end

    # Checks if collection is empty
    def empty?
      items.empty?
    end

    # Return items ids
    def ids
      items.keys
    end

    delegate :each, :to => :items

    private
    attr_reader :items
  end
end
