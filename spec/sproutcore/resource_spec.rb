require 'spec_helper'
require 'action_dispatch/testing/integration'

describe SproutCore::Resource do
  describe "standard resource" do
    class TasksResource < SproutCore::Resource
    end

    before do
      session = ActionDispatch::Integration::Session.new(Rails.application)
      @resource = TasksResource.new(session)
    end

    context "#get" do
      it "should fetch all the records by ids" do
        tasks = [Task.create(:title => "First!"), Task.create(:title => "Foo")]
        hash = @resource.get tasks.map(&:id)

        hash[:tasks].should == tasks
      end
    end

    context "#create" do
      it "should create records from given data hashes" do
        tasks = @resource.create([{:title => "Add more tests"},
                                  {:title => "Be nice", :done => true}])

        tasks.first.title.should == "Add more tests"
        tasks.second.title.should == "Be nice"
        tasks.second.should be_done
        Task.count.should == 2
      end
    end

    context "#update" do
      it "should update records from given data hashes" do
        task = Task.create(:title => "Learn teh internets!")
        @resource.update([{:title => "Learn the internets!", :id => task.id}])

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
end
