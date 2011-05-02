class Bulk::ApiController < ActionController::Base
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
