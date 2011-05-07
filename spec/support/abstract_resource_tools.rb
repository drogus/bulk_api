module ApplicationResourceTools
  def create_application_resource_class(&block)
    klass = Class.new(Bulk::Resource, &block)
    Bulk::Resource.application_resource_class = klass
    klass
  end

  def clean_application_resource_class
    Bulk::Resource.application_resource_class = ApplicationResource
  end
end

RSpec.configuration.include ApplicationResourceTools
