module Sproutcore
  module Generators
    class InstallGenerator < Rails::Generators::Base

      desc <<DESC
Description:
    Creates initializer with configuration and adds required routes
DESC

      def self.source_root
        @source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      end

      def copy_config_initializers_sproutcore
        template 'config/initializers/sproutcore.rb'
      end

      def routes_entry
        route 'sproutcore "/api/bulk"'
      end

    end
  end
end
