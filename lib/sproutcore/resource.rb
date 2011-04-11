class SproutCore::Resource
  attr_reader :session
  cattr_accessor :resource_name

  def initialize(session)
    @session = session
  end

  def self.inherited(base)
    if base.name =~ /(.*)Resource$/
      self.resource_name = $1.underscore.singularize
    end
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

  delegate :resource_name, :to => "self.class"

  private
  def klass
    # TODO: raise nice error if resource_name is not set
    @_klass ||= self.class.resource_name.classify.constantize
  end
end












