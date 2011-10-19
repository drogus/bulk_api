class Bulk::ApiController < ActionController::Base
  after_filter :set_cors_headers
  def get
    options = Bulk::Resource.get(self)
    yield options if block_given?
    render :json => options
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
  
  def options
    set_cors_headers
    render :text => '', :content_type => 'text/plain'
  end
  
  protected
  def set_cors_headers
    headers['Access-Control'] = "allow *"
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, X-SproutCore-Version, Content-Type'
  end
end
