module Bulk
  class AuthenticationError < StandardError; end
  class AuthorizationError < StandardError; end

  class Resource
    module AbstractResourceMixin
      def inherited(base)
        if base.name =~ /(.*)Resource$/
          base.resource_name = $1.underscore.singularize
        end
      end
    end

    attr_reader :controller
    delegate :session, :params, :to => :controller

    class << self
      attr_accessor :resource_name, :resources
      attr_accessor :abstract_resource_class
      attr_reader :abstract
      alias_method :abstract?, :abstract

      def inherited(base)
        if abstract_resource_class
          if self.name == "Bulk::Resource"
            raise "Only one class can inherit from Bulk::Resource, your other resources should inherit from that class (currently it's: #{abstract_resource_class.inspect})"
          else
            super
            return
          end
        end

        self.abstract_resource_class = base
        base.abstract!
        base.extend AbstractResourceMixin
      end

      %w/get create update delete/.each do |method|
        define_method(method) do |controller|
          handle_response(method, controller)
        end
      end

      def abstract!
        @abstract = true
      end
      protected :abstract!

      private

      # TODO: should it belong here or maybe I should move it to Bulk::Engine or some other class?
      # TODO: refactor this to some kind of Response class
      def handle_response(method, controller)
        response = {}
        abstract_resource = abstract_resource_class.new(controller)

        if abstract_resource.respond_to?(:authenticate)
          raise AuthenticationError unless abstract_resource.authenticate
        end

        if abstract_resource.respond_to?(:authorize)
          raise AuthorizationError unless abstract_resource.authorize
        end

        controller.params.each do |resource, hash|
          next unless resources.nil? || resources.include?(resource.to_sym)
          resource_object = instantiate_resource_class(controller, resource)
          next unless resource_object
          collection = resource_object.send(method, hash)
          response.deep_merge! collection.to_hash(resource_object.plural_resource_name)
        end

        { :json => response }
      rescue AuthenticationError
        { :status => 401 }
      rescue AuthorizationError
        { :status => 403 }
      end

      def instantiate_resource_class(controller, resource)
        begin
          "#{resource.to_s.pluralize}_resource".classify.constantize.new(controller)
        rescue NameError
          begin
            new(controller, :resource_name => resource)
          rescue NameError
          end
        end
      end
    end

    def initialize(controller, options = {})
      @controller = controller
      @resource_name = options[:resource_name].to_s if options[:resource_name]

      # try to get klass
      klass unless abstract?
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
    delegate :abstract?, :to => "self.class"

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
