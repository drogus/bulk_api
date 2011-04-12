require 'spec_helper'

describe SproutCore::Engine do
  include Rack::Test::Methods
  def app
    Rails.application
  end

  before do
    SproutCore::Engine.resources :tasks
    SproutCore::Engine.setup!
  end

  it "should provide bulk API" do
    
  end
end
