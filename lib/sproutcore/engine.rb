require 'sproutcore/routes'

module Sproutcore
  class Engine < Rails::Engine
    def self.resources(*resources)
      @resources = resources if resources.length > 0
      @resources
    end

    initializer "do not include root in json" do
      # TODO: handle that nicely
      ActiveRecord::Base.include_root_in_json = false
    end
  end
end
