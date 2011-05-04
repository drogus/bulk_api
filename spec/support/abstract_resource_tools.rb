module AbstractResourceTools
  def create_abstract_resource_class(&block)
    Object.send(:remove_const, :AbstractResource) if defined?(AbstractResource)
    Bulk::Resource.abstract_resource_class = nil

    Class.new(Bulk::Resource, &block)
  end

  def clean_abstract_resource_class
    Object.send(:remove_const, :AbstractResource) if defined?(AbstractResource)
    Bulk::Resource.abstract_resource_class = nil
    Object.const_set(:AbstractResource, Class.new(Bulk::Resource))
  end
end

RSpec.configuration.include AbstractResourceTools
