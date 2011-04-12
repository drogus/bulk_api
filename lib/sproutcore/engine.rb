module Sproutcore
  class Engine < Rails::Engine
    def self.resources(resources = nil)
      @resources = Array.wrap(resources) if resources
      @resources
    end
  end
end
