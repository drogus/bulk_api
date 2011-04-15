require 'spec_helper'
require 'action_dispatch/testing/integration'

describe Sproutcore::Resource do
  shared_examples_for "Sproutcore::Resource subclass" do
    context "#get" do
      before do
        @tasks = [Task.create(:title => "First!"), Task.create(:title => "Foo")]
      end

      it "should fetch records with given ids" do
        hash = @resource.get @tasks.map(&:id)
        hash[:tasks].should == @tasks
      end

      it "should fetch all the records with :all argument" do
        hash = @resource.get :all
        hash[:tasks].should == @tasks
      end

      it "should fetch all the records without arguments" do
        hash = @resource.get
        hash[:tasks].should == @tasks
      end
    end

    context "#create" do
      it "should create records from given data hashes" do
        hash = nil
        lambda {
          hash = @resource.create([{:title => "Add more tests", :_storeKey => 10},
                                   {:title => "Be nice", :done => true, :_storeKey => 5}])
        }.should change(Task, :count).by(2)

        task = hash[:tasks].first
        task.title.should == "Add more tests"
        task[:_storeKey].should == 10

        task = hash[:tasks].second
        task.title.should == "Be nice"
        task.should be_done
        task[:_storeKey].should == 5
      end
    end

    context "#update" do
      it "should update records from given data hashes" do
        task = Task.create(:title => "Learn teh internets!")
        hash = @resource.update([{ :title => "Learn the internets!", :id => task.id }])

        task.reload.title.should == "Learn the internets!"
      end
    end

    context "#delete" do
      it "should delete given records" do
        tasks = [Task.create(:title => "First!"), Task.create(:title => "Foo")]

        lambda {
          @resource.delete(tasks.map(&:id))
        }.should change(Task, :count).by(-2)
      end
    end
  end

  describe "subclassed resource" do
    class TasksResource < Sproutcore::Resource
    end

    before do
      session = ActionDispatch::Integration::Session.new(Rails.application)
      @resource = TasksResource.new(session)
    end

    it_behaves_like "Sproutcore::Resource subclass"
  end

  describe "not subclassed instance with resource name passed" do
    before do
      session = ActionDispatch::Integration::Session.new(Rails.application)
      @resource = Sproutcore::Resource.new(session, :resource_name => :task)
    end

    it_behaves_like "Sproutcore::Resource subclass"
  end
end


