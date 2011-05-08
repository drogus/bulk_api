require 'spec_helper'
require 'generators/bulk/install/install_generator'

describe 'Install generator' do
  include GeneratorSpec::TestCase
  destination File.expand_path("../../tmp", __FILE__)
  tests Bulk::Generators::InstallGenerator

  before do
    prepare_destination
    FileUtils.mkdir(::File.join(destination_root, "config"))
    ::File.open(::File.join(destination_root, "config/routes.rb"), "w") do |f|
      f.puts "Rails.application.routes.draw do\n\nresources :tasks\n\nend\n"
    end
  end

  it 'generates appropriate files' do
    run_generator

    destination_root.should have_structure {
      file "config/routes.rb" do
        contains 'bulk_routes "/api/bulk"'
        contains 'mount Bulk::Sproutcore.new => "/_sproutcore"'
      end

      file "app/bulk/application_resource.rb" do
        contains "class ApplicationResource < Bulk::Resource"
        contains "# resources :tasks, :projects"
      end

      file "config/initializers/bulk_api.rb" do
        contains "# Bulk::Resource.application_resource_class = :ApplicationResource"
      end
    }
  end
end
