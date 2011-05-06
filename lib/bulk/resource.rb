module Bulk
  class AuthenticationError < StandardError; end
  class AuthorizationError < StandardError; end

  class Resource
    module AbstractResourceMixin
      def inherited(base)
        if base.name =~ /(.*)Resource$/
          base.resource_name($1.underscore.singularize)
        end
      end
    end

    attr_reader :controller
    delegate :session, :params, :to => :controller
    delegate :resource_class, :to => "self.class"
    @@resources = []

    class << self
      attr_writer :abstract_resource_class
      attr_reader :abstract
      alias_method :abstract?, :abstract

      def resource_class(klass = nil)
        @resource_class = klass if klass
        @resource_class
      end

      def resource_name(name = nil)
        @resource_name = name if name
        @resource_name
      end

      def resources(*resources)
        @@resources = resources unless resources.blank?
        @@resources
      end

      def abstract_resource_class
        @abstract_resource_class ||= AbstractResource
      end

      def inherited(base)
        if @abstract_resource_class
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
        @@resources = []
      end
      protected :abstract!

      private

      # TODO: refactor this to some kind of Response class
      def handle_response(method, controller)
        response = {}
        abstract_resource = abstract_resource_class.new(controller, :abstract => true)

        if abstract_resource.respond_to?(:authenticate)
          raise AuthenticationError unless abstract_resource.authenticate(method)
        end

        if abstract_resource.respond_to?(:authorize)
          raise AuthorizationError unless abstract_resource.authorize(method)
        end

        controller.params.each do |resource, hash|
          next unless resources.blank? || resources.include?(resource.to_sym)
          resource_object = instantiate_resource_class(controller, resource)
          next unless resource_object
          collection = resource_object.send(method, hash)
          options = {:only_ids => (method == 'delete')}
          response.deep_merge! collection.to_hash(resource_object.plural_resource_name, options)
        end

        { :json => response }
      rescue AuthenticationError
        { :status => 401 }
      rescue AuthorizationError
        { :status => 403 }
      end

      def instantiate_resource_class(controller, resource)
        begin
          "#{resource.to_s.singularize}_resource".classify.constantize.new(controller)
        rescue NameError
          begin
            abstract_resource_class.new(controller, :resource_name => resource)
          rescue NameError
          end
        end
      end
    end

    def initialize(controller, options = {})
      @controller = controller
      @resource_name = options[:resource_name].to_s if options[:resource_name]

      # try to get klass to raise error early if something is not ok
      klass unless options[:abstract]
    end

    def get(ids = 'all')
      all = ids.to_s == 'all'
      collection = Collection.new
      with_records_auth :get, collection, (all ? nil : ids) do
        records = all ? klass.all : klass.where(:id => ids)
        records.each do |r|
          with_record_auth :get, collection, r.id, r do
            collection.set(r.id, r)
          end
        end
      end
      collection
    end

    def create(hashes)
      collection = Collection.new
      ids = hashes.map { |r| r[:_local_id] }
      with_records_auth :create, collection, ids do
        hashes.each do |attrs|
          local_id = attrs.delete(:_local_id)
          record = klass.new(filter_params(attrs))
          record[:_local_id] = local_id
          with_record_auth :create, collection, local_id, record do
            record.save
            set_with_validity_check(collection, local_id, record)
          end
        end
      end
      collection
    end

    def update(hashes)
      collection = Collection.new
      ids = hashes.map { |r| r[:id] }
      with_records_auth :update, collection, ids do
        hashes.each do |attrs|
          attrs.delete(:_local_id)
          record = klass.where(:id => attrs[:id]).first
          with_record_auth :update, collection, record.id, record do
            record.update_attributes(filter_params(attrs))
            set_with_validity_check(collection, record.id, record)
          end
        end
      end
      collection
    end

    def delete(ids)
      collection = Collection.new
      with_records_auth :delete, collection, ids do
        ids.each do |id|
          record = klass.where(:id => id).first
          with_record_auth :delete, collection, record.id, record do
            record.destroy
            set_with_validity_check(collection, record.id, record)
          end
        end
      end
      collection
    end

    def plural_resource_name
      resource_name.to_s.pluralize
    end

    def resource_name
      @resource_name || self.class.resource_name
    end

    private
    delegate :abstract?, :to => "self.class"

    def with_record_auth(action, collection, id, record, &block)
      with_record_authentication(action, collection, id, record) do
        with_record_authorization(action, collection, id, record, &block)
      end
    end

    def with_records_auth(action, collection, ids, &block)
      with_records_authentication(action, collection, ids) do
        with_records_authorization(action, collection, ids, &block)
      end
    end

    def with_record_authentication(action, collection, id, record)
      authenticated = self.respond_to?(:authenticate_record) ? authenticate_record(action, record) : true
      if authenticated
        yield
      else
        collection.errors.set(id, 'not_authenticated')
      end
    end

    def with_record_authorization(action, collection, id, record)
      authorized = self.respond_to?(:authorize_record) ? authorize_record(action, record) : true
      if authorized
        yield
      else
        collection.errors.set(id, 'forbidden')
      end
    end

    def with_records_authentication(action, collection, ids)
      authenticated = self.respond_to?(:authenticate_records) ? authenticate_records(action, klass) : true
      if authenticated
        yield
      else
        ids.each do |id|
          collection.errors.set(id, 'not_authenticated')
        end
      end
    end

    def with_records_authorization(action, collection, ids)
      authorized = self.respond_to?(:authorize_records) ? authorize_records(action, klass) : true
      if authorized
        yield
      else
        ids.each do |id|
          collection.errors.set(id, 'forbidden')
        end
      end
    end

    def set_with_validity_check(collection, id, record)
      collection.set(id, record)
      unless record.errors.empty?
        collection.errors.set(id, :invalid, record.errors.to_hash)
      end
    end

    def filter_params(attributes)
      if self.respond_to?(:params_accessible)
        filter_params_for(:accessible, attributes)
      elsif self.respond_to?(:params_protected)
        filter_params_for(:protected, attributes)
      else
        attributes
      end
    end

    def filter_params_for(type, attributes)
      filter = send("params_#{type}", klass)
      filter = filter ? filter[resource_name.to_sym] : nil

      if filter
        attributes.delete_if do |k, v|
          delete_if = filter.include?(k)
          type == :accessible ? !delete_if : delete_if
        end
      end

      attributes
    end

    def klass
      @_klass ||= begin
        resource_class || (resource_name ? resource_name.to_s.singularize.classify.constantize : nil) ||
          raise("Could not get resource class, please either set resource_class or resource_name that matches model that you want to use")
      rescue NameError
        raise NameError.new("Could not find class matching your resource_name (#{resource_name} - we were looking for #{resource_name.classify})")
      end
    end
  end
end
