require 'bulk/routes'

module Bulk
  class Engine < Rails::Engine
    def self.resources(*resources)
      Bulk::Resource.resources = resources if resources.length > 0
      Bulk::Resource.resources
    end

    initializer "do not include root in json" do
      # TODO: handle that nicely
      ActiveRecord::Base.include_root_in_json = false
    end
  end
end
