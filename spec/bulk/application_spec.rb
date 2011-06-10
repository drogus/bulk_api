require 'spec_helper'

describe Bulk::Application do
  include Rack::Test::Methods

  def app
    subject
  end

  after do
    clean_application_resource_class
  end

  describe "bulk API" do
    before do
      create_application_resource_class do
        resources :tasks, :projects
      end

    end

    let(:task) { Task.create!(:title => "Foo" )}
    let(:project) { Project.create!(:name => "Sproutcore") }

    it "should get given records" do
      get "/api/bulk", { :tasks => [task.id], :projects => [project.id] }

      last_response.body.should include_json({ :tasks => [{:title => "Foo"}]})
      last_response.body.should include_json({ :projects => [{:name => "Sproutcore"}]})
    end

    it "should not raise on not found records" do
      get "/api/bulk", { 
        :tasks    => [task.id,    task.id + 1],
        :projects => [project.id, project.id + 1] 
      }

      last_response.body.should include_json({ :tasks => [{:title => "Foo"}]})
      last_response.body.should include_json({ :projects => [{:name => "Sproutcore"}]})
    end

    it "should update given records" do
      put "/api/bulk", {
        :tasks    => [{:title => "Bar",  :id => task.id}],
        :projects => [{:name => "Rails", :id => project.id}] 
      }

      task.reload.title.should == "Bar"
      project.reload.name.should == "Rails"
    end

    it "should return validation errors on update" do
      another_task    = Task.create(:title => "Bar")
      another_project = Project.create(:name => "jQuery")

      put "/api/bulk", {
        :tasks => [
          {:title => "Bar", :id => task.id},
          {:title => nil,   :id => another_task.id}
        ],
        :projects => [
          {:name => "Rails", :id => project.id},
          {:name => nil,     :id => another_project.id}
        ]
      }

      task.reload.title.should == "Bar"
      project.reload.name.should == "Rails"

      body = JSON.parse(last_response.body)
      body['errors']['tasks'][another_task.id.to_s].should == {'type' => 'invalid', 'data' => {'title' => ["can't be blank"]}}
      body['errors']['projects'][another_project.id.to_s].should == {'type' => 'invalid', 'data' => {'name' => ["can't be blank"]}}
    end

    it "should create given records" do
      lambda {
        lambda {
          post "/api/bulk", { :tasks => [{:title => "Bar"}],
                              :projects => [{:name => "Rails"}] }
        }.should change(Task, :count).by(1)
      }.should change(Project, :count).by(1)
    end

    it "should return validation errors on create" do
      params =  { :tasks => [{:title => "Bar", :_local_id => 10},
                             {:title => nil, :_local_id => 11}],
                  :projects => [{:name => "Rails", :_local_id => 12},
                                {:name => nil, :_local_id => 13}] }

      post "/api/bulk", params

      body = JSON.parse(last_response.body)
      body['errors']['tasks']['11'].should == {'type' => 'invalid', 'data' => {'title' => ["can't be blank"]}}
      body['errors']['projects']['13'].should == {'type' => 'invalid', 'data' => {'name' => ["can't be blank"]}}
      body['tasks'].first['title'].should == "Bar"
      body['projects'].first['name'].should == "Rails"
    end

    it "should delete given records" do
      # Touch records
      task; project

      project_count = Project.count
      task_count    = Task.count

      delete "/api/bulk", { :tasks => [task.id], :projects => [project.id] }

      Project.count.should == project_count - 1
      Task.count.should    == task_count - 1

      body = JSON.parse(last_response.body)
      body["tasks"].should == [task.id]
      body["projects"].should == [project.id]
    end
  end

  describe "bulk API with only :tasks enabled" do
    before do
      create_application_resource_class do
        resources :tasks
      end
    end

    let(:task)    { Task.create!(:title => "Foo" ) }
    let(:project) { Project.create!(:name => "Sproutcore") }

    it "should get only tasks" do
      get "/api/bulk", { :tasks => [task.id], :projects => [project.id] }

      last_response.body.should include_json({:tasks => [{:title => "Foo"}]})
      last_response.body.should_not include_json({:projects => []})
    end

    it "should update only tasks" do
      put "/api/bulk", {
        :tasks    => [{:title => "Bar",  :id => task.id}],
        :projects => [{:name => "Rails", :id => project.id}]
      }

      task.reload.title.should == "Bar"
      project.reload.name.should == "Sproutcore"
    end

    it "should create only tasks" do
      project_count = Project.count
      task_count    = Task.count

      post "/api/bulk", {
        :tasks => [{:title => "Bar"}],
        :projects => [{:name => "Rails"}] 
      }

      Project.count.should == project_count
      Task.count.should == task_count + 1
  end

    it "should delete only tasks" do
      # Touch records
      project; task

      lambda do
        lambda do
          delete "/api/bulk", { :tasks => [task.id], :projects => [project.id] }
        end.should change(Task, :count).by(-1)
      end.should_not change(Project, :count)
    end
  end

  context "with custom application class" do
    before { clean_application_resource_class }

    it "should properly render 401 response on auth error" do
      klass = Class.new(Bulk::Resource) do
        def authenticate(action)
          false
        end
      end
      Bulk::Resource.application_resource_class = klass

      get "/api/bulk"
      last_response.status.should == 401
    end

    it "should properly render 403 response on authorization error" do
      klass = Class.new(Bulk::Resource) do
        def authorize(action)
          false
        end
      end
      Bulk::Resource.application_resource_class = klass

      get "/api/bulk"
      last_response.status.should == 403
    end
  end
end
