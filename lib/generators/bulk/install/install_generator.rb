module Bulk
  module Generators
    class InstallGenerator < Rails::Generators::Base

      desc <<DESC
Description:
    Creates initializer with configuration.
DESC

      def self.source_root
        @source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
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
