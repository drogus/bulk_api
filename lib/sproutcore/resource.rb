class Sproutcore::Resource
  attr_reader :session

  class << self
    attr_accessor :resource_name

    def inherited(base)
      if base.name =~ /(.*)Resource$/
        base.resource_name = $1.underscore.singularize
      end
    end
  end

  def initialize(session, options = {})
    @session = session
    @resource_name = options[:resource_name].to_s if options[:resource_name]
  end

  def get(ids)
    klass
  end

  def get(ids)
    { plural_resource_name.to_sym => klass.where(:id => ids) }
  end

  def create(tasks)
    tasks.map do |task|
      klass.create(task)
    end
  end

  def update(tasks)
    tasks.map do |hash|
      task = klass.find(hash[:id])
      task.update_attributes(hash)
      task
    end
  end

  def delete(ids)
    ids.each { |id| klass.destroy(id) }
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












