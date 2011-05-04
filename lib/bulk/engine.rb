require 'bulk/routes'

module Bulk
  class Engine < Rails::Engine
    initializer "do not include root in json" do
      # TODO: handle that nicely
      ActiveRecord::Base.include_root_in_json = false
    end
  end
end
