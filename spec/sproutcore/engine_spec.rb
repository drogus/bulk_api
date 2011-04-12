require 'spec_helper'

describe Sproutcore::Engine do
  include Rack::Test::Methods
  def app
    Rails.application
  end

  describe "bulk API" do
    before do
      Sproutcore::Engine.resources :tasks, :projects

      @task = Task.create(:title => "Foo")
      @project = Project.create(:name => "Sproutcore")
    end

    it "should get given records" do
      get "/api/bulk", { :tasks => [@task.id], :projects => [@project.id] }

      last_response.body.should include_json({ :tasks => [{:title => "Foo"}]})
      last_response.body.should include_json({ :projects => []})
    end

    it "should update given records" do
      put "/api/bulk", { :tasks => [{:title => "Bar", :id => @task.id}],
                         :projects => [{:name => "Rails", :id => @project.id}] }

      @task.reload.title.should == "Bar"
      @project.reload.name.should == "Rails"
    end

    it "should create given records" do
      lambda {
        lambda {
          post "/api/bulk", { :tasks => [{:title => "Bar"}],
                              :projects => [{:name => "Rails"}] }
        }.should change(Task, :count).by(1)
      }.should change(Project, :count).by(1)
    end

    it "should delete given records" do
      lambda {
        lambda {
          delete "/api/bulk", { :tasks => [@task.id],
                                :projects => [@project.id] }
        }.should change(Task, :count).by(-1)
      }.should change(Project, :count).by(-1)
    end
  end

  describe "bulk API with only :tasks enabled" do
    before do
      Sproutcore::Engine.resources :tasks

      @task = Task.create(:title => "Foo")
      @project = Project.create(:name => "Sproutcore")
    end

    it "should get only tasks" do
      get "/api/bulk", { :tasks => [@task.id], :projects => [@project.id] }

      last_response.body.should include_json({ :tasks => [{:title => "Foo"}]})
      last_response.body.should_not include_json({ :projects => []})
    end

    it "should update only tasks" do
      put "/api/bulk", { :tasks => [{:title => "Bar", :id => @task.id}],
                         :projects => [{:name => "Rails", :id => @project.id}] }

      @task.reload.title.should == "Bar"
      @project.reload.name.should == "Sproutcore"
    end

    it "should create only tasks" do
      lambda {
        lambda {
          post "/api/bulk", { :tasks => [{:title => "Bar"}],
                              :projects => [{:name => "Rails"}] }
        }.should change(Task, :count).by(1)
      }.should_not change(Project, :count)
    end

    it "should delete only tasks" do
      lambda {
        lambda {
          delete "/api/bulk", { :tasks => [@task.id],
                                :projects => [@project.id] }
        }.should change(Task, :count).by(-1)
      }.should_not change(Project, :count)
    end
  end
end
