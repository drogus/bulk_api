module ApplicationResourceTools
  def create_application_resource_class(&block)
    Object.send(:remove_const, :ApplicationResource) if defined?(ApplicationResource)
    Bulk::Resource.application_resource_class = nil

    Class.new(Bulk::Resource, &block)
  end

  def clean_application_resource_class
    Object.send(:remove_const, :ApplicationResource) if defined?(ApplicationResource)
    Bulk::Resource.application_resource_class = nil
    Object.const_set(:ApplicationResource, Class.new(Bulk::Resource))
  end
end

RSpec.configuration.include ApplicationResourceTools
