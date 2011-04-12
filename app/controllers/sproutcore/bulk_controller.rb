class Sproutcore::BulkController < ActionController::Base
  def get
    render :json => Sproutcore::Resource.get(session, params)
  end

  def create
    render :json => Sproutcore::Resource.create(session, params)
  end

  def update
    render :json => Sproutcore::Resource.update(session, params)
  end

  def delete
    render :json => Sproutcore::Resource.delete(session, params)
  end

end
