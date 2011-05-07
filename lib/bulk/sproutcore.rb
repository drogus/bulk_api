require 'sproutcore'
require 'sproutcore/rack/service'
require 'sproutcore/models/project'

module Bulk
  class Sproutcore
    attr_reader :path

    def initialize(options = {})
      @path = options[:path]
      @prefix = options[:prefix]
      SC.prefix = @prefix
    end

    def sproutcore
      @sproutcore ||= begin
        project = SC::Project.load File.expand_path(path), :parent => SC.builtin_project
        SC::Rack::Service.new(project)
      end
    end

    def call(env)
      env["PATH_INFO"] = "/" if env["PATH_INFO"].blank?
      sproutcore.call(env)
    end
  end
end
