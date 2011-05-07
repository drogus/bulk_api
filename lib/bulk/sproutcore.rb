require 'sproutcore'
require 'sproutcore/rack/service'
require 'sproutcore/models/project'

module Bulk
  class Sproutcore
    def sproutcore
      @sproutcore ||= begin
        project = SC::Project.load Rails.application.paths["app/sproutcore"].first, :parent => SC.builtin_project
        SC::Rack::Service.new(project)
      end
    end

    def call(env)
      env["PATH_INFO"] = "/" if env["PATH_INFO"].blank?
      sproutcore.call(env)
    end
  end
end
