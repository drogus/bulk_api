class Bulk::ApiController < ActionController::Base
  # Do not wrap parameters into a nested hash. This behaviour was
  # introduced with rails 3.1 and blows up resource handling.
  wrap_parameters :format => [] if respond_to?(:wrap_parameters)

  def get
    options = Bulk::Resource.get(self)
    yield options if block_given?
    render options
  end

  def create
    options = Bulk::Resource.create(self)
    yield options if block_given?
    render options
  end

  def update
    options = Bulk::Resource.update(self)
    yield options if block_given?
    render options
  end

  def delete
    options = Bulk::Resource.delete(self)
    yield options if block_given?
    render options
  end
end
