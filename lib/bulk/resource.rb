module Bulk
  class Resource
    attr_reader :session

    class << self
      attr_accessor :resource_name, :resources

      def inherited(base)
        if base.name =~ /(.*)Resource$/
          base.resource_name = $1.underscore.singularize
        end
      end

      # TODO: should it belong here or maybe I should move it to Bulk::Engine or some other class?
      def handle_response(method, session, params)
        response = {}
        params.each do |resource, hash|
          next unless resources.nil? || resources.include?(resource.to_sym)
          resource_object = instantiate(session, resource)
          next unless resource_object
          collection = resource_object.send(method, hash)
          response.deep_merge! collection.to_hash(resource_object.plural_resource_name)
        end
        response
      end

      %w/get create update delete/.each do |method|
        define_method(method) do |session, params|
          handle_response(method, session, params)
        end
      end

      def instantiate(session, resource)
        begin
          "#{resource.to_s.pluralize}_resource".classify.constantize.new(session)
        rescue NameError
          begin
            new(session, :resource_name => resource)
          rescue NameError
          end
        end
      end
    end

    def initialize(session, options = {})
      @session = session
      @resource_name = options[:resource_name].to_s if options[:resource_name]

      # try to get klass
      klass
    end

    def get(ids = 'all')
      records = ids.to_s == 'all' ? klass.all : klass.where(:id => ids)
      get_collection_from_records_array(records)
    end

    def create(hashes)
      collection = Collection.new
      records = hashes.each do |attrs|
        local_id = attrs.delete(:_local_id)
        record = klass.create(attrs)
        record[:_local_id] = local_id
        set_with_validity_check(collection, local_id, record)
      end

      collection
    end

    def update(hashes)
      collection = Collection.new
      hashes.each do |attrs|
        attrs.delete(:_local_id)
        record = klass.where(:id => attrs[:id]).first
        if record
          record.update_attributes(attrs)
          set_with_validity_check(collection, record.id, record)
        end
      end

      collection
    end

    def delete(ids)
      collection = Collection.new
      ids.each do |id|
        record = klass.where(:id => id).first
        if record
          record.destroy
          set_with_validity_check(collection, record.id, record)
        end
      end

      collection
    end

    def plural_resource_name
      resource_name.pluralize
    end

    def resource_name
      @resource_name || self.class.resource_name
    end

    private
    def set_with_validity_check(collection, id, record)
      collection.set(id, record)
      unless record.errors.empty?
        collection.errors.set(id, :invalid, record.errors.to_hash)
      end
    end

    def get_collection_from_records_array(records)
      collection = Collection.new
      records.each { |r| collection.set(r.id, r) }
      collection
    end

    def klass
      # TODO: raise nice error if resource_name is not set
      @_klass ||= resource_name.classify.constantize
    end
  end
end
