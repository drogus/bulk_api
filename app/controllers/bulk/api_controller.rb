class Bulk::ApiController < ActionController::Base
  def get
    options = { :json => Bulk::Resource.get(session, params) }
    yield options if block_given?
    render options
  end

  def create
    options = { :json => Bulk::Resource.create(session, params) }
    yield options if block_given?
    render options
  end

  def update
    options = { :json => Bulk::Resource.update(session, params) }
    yield options if block_given?
    render options
  end

  def delete
    options = { :json => Bulk::Resource.delete(session, params) }
    yield options if block_given?
    render options
  end
end
