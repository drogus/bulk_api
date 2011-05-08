module Bulk
  module Generators
    class InstallGenerator < Rails::Generators::Base

      desc <<DESC
Description:
    Creates initializer with configuration and adds required routes
DESC

      def self.source_root
        @source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      end

      def routes_entry
        route 'bulk_routes "/api/bulk"'
        route 'mount Bulk::Sproutcore.new => "/_sproutcore"'
      end

      def copy_app_bulk_application_resource
        template 'app/bulk/application_resource.rb'
      end

      def copy_initializers_bulk_api
        template "config/initializers/bulk_api.rb"
      end
    end
  end
end
