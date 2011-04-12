class Sproutcore::Resource
  attr_reader :session

  class << self
    attr_accessor :resource_name, :resources

    def inherited(base)
      if base.name =~ /(.*)Resource$/
        base.resource_name = $1.underscore.singularize
      end
    end

    # TODO: should it belong here or maybe I should move it to Sproutcore::Engine or some other class?
    def handle_response(method, session, params)
      response = {}
      params.each do |resource, hash|
        next unless resources.include?(resource.to_sym)
        klass = klass(session, resource)
        response.merge! klass.send(method, hash)
      end
      response
    end

    %w/get create update delete/.each do |method|
      define_method(method) do |session, params|
        handle_response(method, session, params)
      end
    end

    def klass(session, resource)
      begin
        "#{resource.to_s.pluralize}_resource".classify.constantize.new(session)
      rescue NameError
        new(session, :resource_name => resource)
      end
    end

    def resources
      # TODO: probably I should not depend on Sproutcore::Engine
      Sproutcore::Engine.resources.map(&:to_sym)
    end
  end

  def initialize(session, options = {})
    @session = session
    @resource_name = options[:resource_name].to_s if options[:resource_name]
  end

  def get(ids)
    { plural_resource_name.to_sym => klass.where(:id => ids) }
  end

  def create(hashes)
    records = hashes.map do |attrs|
      klass.create(attrs)
    end

    { plural_resource_name.to_sym => records }
  end

  def update(hashes)
    records = hashes.map do |attrs|
      klass.find(attrs[:id]).tap do |record|
        record.update_attributes(attrs)
      end
    end

    { plural_resource_name.to_sym => records }
  end

  def delete(ids)
    ids.each { |id| klass.destroy(id) }

    { plural_resource_name.to_sym => ids }
  end

  def plural_resource_name
    resource_name.pluralize
  end

  def resource_name
    @resource_name || self.class.resource_name
  end

  private
  def klass
    # TODO: raise nice error if resource_name is not set
    @_klass ||= resource_name.classify.constantize
  end
end
