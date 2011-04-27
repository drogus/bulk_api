module Bulk
  module Generators
    class ResourceGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("../templates", __FILE__)

      check_class_collision :suffix => "Resource"

      def generate_part_class
        template "resource.rb", "app/bulk/#{file_name}_resource.rb"
      end
    end
  end
end
