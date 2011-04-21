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
        next unless resources.nil? || resources.include?(resource.to_sym)
        klass = klass(session, resource)
        next unless klass
        response.deep_merge! klass.send(method, hash)
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
    objects = ids.to_s == 'all' ? klass.all : klass.where(:id => ids)
    { plural_resource_name.to_sym => objects }
  end

  def create(hashes)
    records = hashes.map do |attrs|
      store_key = attrs.delete(:_storeKey)
      klass.create(attrs).tap { |r| r[:_storeKey] = store_key }
    end

    response(records)
  end

  def update(hashes)
    records = hashes.map do |attrs|
      attrs.delete(:_storeKey)
      record = klass.where(:id => attrs[:id]).first
      record.update_attributes(attrs) if record
      record
    end.compact

    response(records, :errors_key => :id)
  end

  def delete(ids)
    records = ids.map { |id|
      record = klass.where(:id => id).first
      record.destroy if record
      record
    }.compact

    response(records, :errors_key => :id, :only_ids => true)
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

  def response(records, options = {})
    defaults = { :errors_key => :_storeKey }
    options = defaults.merge(options)

    valid, invalid = records.partition { |r| r.errors.length == 0 }
    invalid = Hash[*invalid.map {|r| [r[options[:errors_key]], r.errors]}.flatten]

    valid.map!(&:id) if options[:only_ids]

    {
      plural_resource_name.to_sym => valid,
      :errors => {
        plural_resource_name.to_sym => invalid
      }
    }
  end
end
