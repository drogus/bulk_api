require 'spec_helper'
require 'action_dispatch/testing/integration'

describe Bulk::Resource do
  it "should raise error when trying to inherit from it while some other class already inherits from it" do
    lambda do
      Class.new(Bulk::Resource)
    end.should raise_error("Only one class can inherit from Bulk::Resource, your other resources should inherit from that class (currently it's: AbstractResource)")
  end

  context "global authentication" do
    it "should run authentication callback before handling request" do
      abstract_resource = Class.new do
        cattr_accessor :authenticated
        self.authenticated = false

        define_method(:authenticate) do
          self.class.authenticated = true
        end
      end
      Bulk::Resource.abstract_resource_class = abstract_resource

      controller = mock("controlelr", :params => {})
      result = Bulk::Resource.get(controller)
      abstract_resource.authenticated.should == true
      result[:status].should be_nil
    end

    it "should set 401 status if authentication fails" do
      abstract_resource = Class.new do
        define_method(:authenticate) { false }
      end
      Bulk::Resource.abstract_resource_class = abstract_resource

      controller = mock("controlelr", :params => {})
      result = Bulk::Resource.get(controller)
      result[:status].should == 401
    end
  end

  context "global authorization" do
    it "should run authorization callback before handling request" do
      abstract_resource = Class.new do
        cattr_accessor :authorized
        self.authorized = false

        define_method(:authorize) do
          self.class.authorized = true
        end
      end
      Bulk::Resource.abstract_resource_class = abstract_resource

      controller = mock("controlelr", :params => {})
      result = Bulk::Resource.get(controller)
      abstract_resource.authorized.should == true
      result[:status].should be_nil
    end

    it "should set 403 status if authentication fails" do
      abstract_resource = Class.new do
        define_method(:authorize) { false }
      end
      Bulk::Resource.abstract_resource_class = abstract_resource

      controller = mock("controlelr", :params => {})
      result = Bulk::Resource.get(controller)
      result[:status].should == 403
    end
  end

  shared_examples_for "Bulk::Resource subclass" do
    context "#get" do
      before do
        @tasks = [Task.create(:title => "First!"), Task.create(:title => "Foo")]
      end

      it "should fetch records with given ids" do
        collection = @resource.get @tasks.map(&:id)
        collection.ids.sort.should == @tasks.map {|t| t.id.to_s }.sort
      end

      it "should fetch all the records with :all argument" do
        collection = @resource.get :all
        collection.length.should == 2
        collection.ids.sort.should == @tasks.map {|t| t.id.to_s }.sort
      end

      it "should fetch all the records without arguments" do
        collection = @resource.get
        collection.length.should == 2
        collection.ids.sort.should == @tasks.map {|t| t.id.to_s }.sort
      end
    end

    context "#create" do
      it "should create records from given data hashes" do
        collection = nil
        lambda {
          collection = @resource.create([{:title => "Add more tests", :_local_id => 10},
                                         {:title => "Be nice", :done => true, :_local_id => 5}])
        }.should change(Task, :count).by(2)

        task = collection.get(10)
        task.title.should == "Add more tests"
        task[:_local_id].should == 10

        task = collection.get(5)
        task.title.should == "Be nice"
        task.should be_done
        task[:_local_id].should == 5
      end

      it "should return errors in a hash with local_id as index for records" do
        collection = @resource.create([{:title => "Add more tests", :_local_id => 10},
                                       {:_local_id => 11}])

        error = collection.errors.get(11)
        error.data.should == {:title => ["can't be blank"]}
        error.type.should == :invalid
        collection.get(10).title.should == "Add more tests"
      end
    end

    context "#update" do
      it "should update records from given data hashes" do
        task = Task.create(:title => "Learn teh internets!")
        collection = @resource.update([{ :title => "Learn the internets!", :id => task.id }])

        task.reload.title.should == "Learn the internets!"
      end

      it "should just skip non existing records without throwing an error" do
        task = Task.create(:title => "Learn teh internets!")
        collection = @resource.update([{:title => "blah!", :id => 1},
                                       { :title => "Learn the internets!", :id => task.id }])

        task.reload.title.should == "Learn the internets!"
        collection.length.should == 1
      end

      it "should return collection with errors" do
        task = Task.create(:title => "Learn teh internets!")
        task1 = Task.create(:title => "Lame task")
        collection = @resource.update([{:id => task.id, :title => "Changed", :_local_id => 10},
                                       {:id => task1.id, :title => nil, :_local_id => 11}])

        error = collection.errors.get(task1.id)
        error.type.should == :invalid
        error.data.should == {:title => ["can't be blank"]}
        collection.get(task.id).title.should == "Changed"
        collection.length.should == 2
      end

    end

    context "#delete" do
      it "should skip non existing records" do
        task = Task.create(:title => "Learn teh internets!")
        collection = @resource.delete(:tasks => [task.id, task.id + 1])

        collection.ids.should == [task.id.to_s]
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

          collection = nil
          lambda {
            collection = @resource.delete(tasks.map(&:id))
          }.should change(Task, :count).by(-2)

          error = collection.errors.get(task1.id)
          error.data.should == {:base => ["You can't destroy me noob!"]}
          error.type.should == :invalid
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
        controller = mock("controller", :params => { :tasks => [1], :todos => [2] })
        Bulk::Resource.get(controller)
      }.should_not raise_error
    end
  end

  describe "subclassed resource" do
    class TasksResource < AbstractResource
    end

    before do
      controller = mock("controller", :params => {})
      @resource = TasksResource.new(controller)
    end

    it_behaves_like "Bulk::Resource subclass"
  end

  describe "not subclassed instance with resource name passed" do
    before do
      controller = mock("controller", :params => {})
      @resource = Bulk::Resource.new(controller, :resource_name => :task)
    end

    it_behaves_like "Bulk::Resource subclass"
  end
end


