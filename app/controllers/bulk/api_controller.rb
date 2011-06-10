class Bulk::ApiController < ActionController::Base
  # Do not wrap parameters into a nested hash. This behaviour was
  # introduced with rails 3.1 and blows up resource handling.
  wrap_parameters :format => [] if respond_to?(:wrap_parameters)

  def get
    options = Bulk::Resource.get(request)
    yield options if block_given?
    render options
  end

  def create
    options = Bulk::Resource.create(request)
    yield options if block_given?
    render options
  end

  def update
    options = Bulk::Resource.update(request)
    yield options if block_given?
    render options
  end

  def delete
    options = Bulk::Resource.delete(request)
    yield options if block_given?
    render options
  end
end
