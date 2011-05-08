require 'bulk/routes'

module Bulk
  class Engine < Rails::Engine
    initializer "do not include root in json" do
      # TODO: handle that nicely
      ActiveRecord::Base.include_root_in_json = false
    end

    initializer "require sproutcore Rack app" do
      # it needs to be done after rails load, otherwise haml freaks out
      require 'bulk/sproutcore'
    end

    config.paths.add "app/bulk", :eager_load => true
    config.paths.add "app/sproutcore"
  end
end
