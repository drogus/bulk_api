require 'bulk/routes'

module Bulk
  class Engine < Rails::Engine
    initializer "do not include root in json" do
      # TODO: handle that nicely
      ActiveRecord::Base.include_root_in_json = false if defined? ActiveRecord
    end

    initializer "config paths" do |app|
      app.config.paths.add "app/bulk", :eager_load => true
    end
  end
end
