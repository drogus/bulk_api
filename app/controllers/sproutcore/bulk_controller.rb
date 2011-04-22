class Sproutcore::BulkController < ActionController::Base
  def get
    options = { :json => Sproutcore::Resource.get(session, params) }
    yield options if block_given?
    render options
  end

  def create
    options = { :json => Sproutcore::Resource.create(session, params) }
    yield options if block_given?
    render options
  end

  def update
    options = { :json => Sproutcore::Resource.update(session, params) }
    yield options if block_given?
    render options
  end

  def delete
    options = { :json => Sproutcore::Resource.delete(session, params) }
    yield options if block_given?
    render options
  end
end
