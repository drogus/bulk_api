require 'spec_helper'
require 'generators/bulk/resource/resource_generator'

describe 'Bulk::Resource generator' do
  include GeneratorSpec::TestCase
  destination File.expand_path("../../tmp", __FILE__)
  tests Bulk::Generators::ResourceGenerator
  before do
    prepare_destination
  end

  it 'generates file in app/bulk/ dir' do
    run_generator ["task"]

    destination_root.should have_structure {
      directory "app/bulk" do
        file "task_resource.rb" do
          contains "class TaskResource < ApplicationResource\nend\n"
        end
      end
    }
  end
end
