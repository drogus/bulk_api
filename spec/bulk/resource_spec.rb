require 'spec_helper'
require 'action_dispatch/testing/integration'

describe Bulk::Resource do
  shared_examples_for "Bulk::Resource subclass" do
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
          hash = @resource.create([{:title => "Add more tests", :_local_id => 10},
                                   {:title => "Be nice", :done => true, :_local_id => 5}])
        }.should change(Task, :count).by(2)

        task = hash[:tasks].first
        task.title.should == "Add more tests"
        task[:_local_id].should == 10

        task = hash[:tasks].second
        task.title.should == "Be nice"
        task.should be_done
        task[:_local_id].should == 5
      end

      it "should return errors in a hash with local_id as index for records" do
        hash = @resource.create([{:title => "Add more tests", :_local_id => 10},
                                 {:_local_id => 11}])

        errors = hash[:errors][:tasks]
        errors.length.should == 1
        errors[11].should == {:title => ["can't be blank"]}
        hash[:tasks].first.title.should == "Add more tests"
        hash[:tasks].length.should == 1
      end

    end

    context "#update" do
      it "should update records from given data hashes" do
        task = Task.create(:title => "Learn teh internets!")
        hash = @resource.update([{ :title => "Learn the internets!", :id => task.id }])

        task.reload.title.should == "Learn the internets!"
      end

      it "should just skip non existing records without throwing an error" do
        task = Task.create(:title => "Learn teh internets!")
        hash = @resource.update([{:title => "blah!", :id => 1},
                                 { :title => "Learn the internets!", :id => task.id }])

        task.reload.title.should == "Learn the internets!"
      end

      it "should return errors in a hash with id as index for records" do
        task = Task.create(:title => "Learn teh internets!")
        task1 = Task.create(:title => "Lame task")
        hash = @resource.update([{:id => task.id, :title => "Changed", :_local_id => 10},
                                 {:id => task1.id, :title => nil, :_local_id => 11}])

        errors = hash[:errors][:tasks]
        errors.length.should == 1
        errors[task1.id].should == {:title => ["can't be blank"]}
        hash[:tasks].first.title.should == "Changed"
        hash[:tasks].length.should == 1
      end

    end

    context "#delete" do
      it "should skip non existing records" do
        task = Task.create(:title => "Learn teh internets!")
        hash = @resource.delete(:tasks => [task.id, task.id + 1])

        hash[:tasks].should == [task.id]
      end

      it "should delete given records" do
        begin
          Task.class_eval do
            before_destroy :cant_delete
            def cant_delete
              if title != "First!"
                errors.add(:base, "You can't destroy me noob!")
              end
            end
          end

          task = Task.create(:title => "First!")
          task1 = Task.create(:title => "Foo")
          tasks = [task, task1]

          hash = nil
          lambda {
            hash = @resource.delete(tasks.map(&:id))
          }.should change(Task, :count).by(-2)

          hash[:tasks].should == [task.id]
          errors = hash[:errors][:tasks]
          errors.length.should == 1
          errors[task1.id].should == {:base => ["You can't destroy me noob!"]}
        ensure
          Task.class_eval do
            def cant_delete
              true
            end
          end
        end
      end
    end
  end

  describe "without specifing available resources" do
    before do
      @old_resources = Bulk::Resource.resources
      Bulk::Resource.resources = nil
    end

    after do
      Bulk::Resource.resources = @old_resources
    end

    it "should skip resources that can't be resolved into classes" do
      lambda {
        Bulk::Resource.get(nil, :tasks => [1], :todos => [2])
      }.should_not raise_error
    end
  end

  describe "subclassed resource" do
    class TasksResource < Bulk::Resource
    end

    before do
      session = ActionDispatch::Integration::Session.new(Rails.application)
      @resource = TasksResource.new(session)
    end

    it_behaves_like "Bulk::Resource subclass"
  end

  describe "not subclassed instance with resource name passed" do
    before do
      session = ActionDispatch::Integration::Session.new(Rails.application)
      @resource = Bulk::Resource.new(session, :resource_name => :task)
    end

    it_behaves_like "Bulk::Resource subclass"
  end
end


