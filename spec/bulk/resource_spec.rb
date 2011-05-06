require 'spec_helper'
require 'action_dispatch/testing/integration'

describe Bulk::Resource do
  def standard_get
    @task    = Task.create(:title => 'task', :done => true)
    @project = Project.create(:name => 'project', :description => 'desc')
    controller = mock("controller", :params => {:tasks => [@task.id], :projects => [@project.id]})
    Bulk::Resource.get(controller)
  end

  def standard_update
    @task    = Task.create(:title => 'My Task')
    @project = Project.create(:name => 'SproutCore')
    params = {
      :projects => [{:_local_id => '10', :name => 'project', :description => 'desc', :id => @project.id}],
      :tasks => [{:_local_id => '5', :title => 'task', :done => true, :id => @task.id}]
    }
    controller = mock("controller", :params => params)
    Bulk::Resource.update(controller)
  end

  def standard_create
    params = {
      :projects => [{:_local_id => '10', :name => 'project', :description => 'desc'}],
      :tasks => [{:_local_id => '5', :title => 'task', :done => true}]
    }
    controller = mock("controller", :params => params)
    Bulk::Resource.create(controller)
  end

  def standard_delete
    @task    = Task.create(:title => 'task', :done => true)
    @project = Project.create(:name => 'project', :description => 'desc')
    params = {
      :projects => [@project.id],
      :tasks => [@task.id]
    }
    controller = mock("controller", :params => params)
    Bulk::Resource.delete(controller)
  end

  after do
    clean_abstract_resource_class
  end

  it "should raise error when trying to inherit from it while some other class already inherits from it" do
    clean_abstract_resource_class
    lambda do
      Class.new(Bulk::Resource)
    end.should raise_error("Only one class can inherit from Bulk::Resource, your other resources should inherit from that class (currently it's: AbstractResource)")
  end

  it "should allow to set resource class" do
    klass = Class.new(AbstractResource) do
      resource_class Task
    end

    task = Task.create(:title => "First!")
    controller = mock("controller", :params => {})
    collection = klass.new(controller).get
    collection.get(task.id).should == task
  end

  it "should raise custom error if resource_name is not set properly" do
    klass = Class.new(AbstractResource) do
    end

    lambda { klass.new(nil) }.should raise_error("Could not get resource class, please either set resource_class or resource_name that matches model that you want to use")
  end

  it "should raise custom error if class cannot be found using resource_name" do
    klass = Class.new(AbstractResource) do
      resource_name "something"
    end

    lambda { klass.new(nil) }.should raise_error("Could not find class matching your resource_name (something - we were looking for Something)")
  end

  it "should run authentication callbacks before authorization callbacks" do
    klass = create_abstract_resource_class do
      cattr_accessor :callbacks
      self.callbacks = []

      def authenticate_records(action, klass)
        self.class.callbacks << :authenticate_records
      end

      def authenticate_record(action, record)
        self.class.callbacks << :authenticate_record
      end

      def authenticate(action)
        self.class.callbacks << :authenticate
      end

      def authorize_records(action, klass)
        self.class.callbacks << :authorize_records
      end

      def authorize_record(action, record)
        self.class.callbacks << :authorize_record
      end

      def authorize(action)
        self.class.callbacks << :authorize
      end
    end
    params = {
      :projects => [{:_local_id => '10', :name => 'SproutCore'}],
    }
    controller = mock("controller", :params => params)
    result = Bulk::Resource.create(controller)
    klass.callbacks.should == [:authenticate, :authorize, :authenticate_records, :authorize_records, :authenticate_record, :authorize_record]
  end

  context "callbacks priority" do
    before do
      @klass = create_abstract_resource_class do
        def self.callbacks
          @@callbacks ||= []
        end

        def self.clear_callbacks
          @@callbacks = nil
        end

        def authenticate_record(action, record)
          self.class.callbacks << :abstract_authenticate_record
        end

        def authenticate_records(action, klass)
          self.class.callbacks << :abstract_authenticate_records
        end

        def authenticate(action)
          self.class.callbacks << :abstract_authenticate
        end

        def authorize_record(action, record)
          self.class.callbacks << :abstract_authorize_record
        end

        def authorize_records(action, klass)
          self.class.callbacks << :abstract_authorize_records
        end

        def authorize(action)
          self.class.callbacks << :abstract_authorize
        end
      end

      tasks_class = Class.new(@klass) do
        resource_class Task
        resource_name :tasks

        def authenticate_record(action, record)
          self.class.callbacks << :tasks_authenticate_record
        end

        def authenticate_records(action, klass)
          self.class.callbacks << :tasks_authenticate_records
        end

        def authenticate(action)
          self.class.callbacks << :tasks_authenticate
        end

        def authorize_record(action, record)
          self.class.callbacks << :tasks_authorize_record
        end

        def authorize_records(action, klass)
          self.class.callbacks << :tasks_authorize_records
        end

        def authorize(action)
          self.class.callbacks << :tasks_authorize
        end
      end

      Object.const_set(:TaskResource, tasks_class)
    end

    after do
      Object.send(:remove_const, :TaskResource)
    end

    it "should run resource specific callbacks if they exist" do
      task = Task.create(:title => 'task')
      controller = mock("controller", :params => {:tasks => [task.id]})
      result = Bulk::Resource.get(controller)
      @klass.callbacks.should == [:abstract_authenticate, :abstract_authorize, :tasks_authenticate_records, :tasks_authorize_records, :tasks_authenticate_record, :tasks_authorize_record]
    end
  end

  context "as_json" do
    before do
      @klass = create_abstract_resource_class do
        def as_json(klass)
          case klass.name
          when "Project"
            { :only => [:name] }
          when "Task"
            { :only => [:title] }
          end
        end
      end
    end

    it "should filter attributes on get" do
      result = standard_get
      expected = { :tasks => [{:title => "task"}], :projects => [{:name => "project"}] }
      result.should include_json(:json => expected)
      not_expected = { :tasks => [{:done => true}], :projects => [{:description => 'desc'}] }
      result.should_not include_json(:json => not_expected)
    end

    it "should filter attributes on create" do
      result = standard_create
      expected = { :tasks => [{:title => "task"}], :projects => [{:name => "project"}] }
      result.should include_json(:json => expected)
      not_expected = { :tasks => [{:done => true}], :projects => [{:description => 'desc'}] }
      result.should_not include_json(:json => not_expected)
    end

    it "should filter attributes on update" do
      result = standard_update
      expected = { :tasks => [{:title => "task"}], :projects => [{:name => "project"}] }
      result.should include_json(:json => expected)
      not_expected = { :tasks => [{:done => true}], :projects => [{:description => 'desc'}] }
      result.should_not include_json(:json => not_expected)
    end

    context "with custom resource class" do
      before do
        tasks_class = Class.new(@klass) do
          resource_class Task
          resource_name :tasks

          def as_json(klass)
            { :only => [:done] }
          end
        end

        Object.const_set(:TaskResource, tasks_class)
      end

      after do
        Object.send(:remove_const, :TaskResource)
      end

      it "should override as_json attributes on get" do
        result = standard_get
        expected = { :tasks => [{:done => true}], :projects => [{:name => 'project'}] }
        result.should include_json(:json => expected)
        not_expected = { :tasks => [{:title => "task"}], :projects => [{:description => "desc"}] }
        result.should_not include_json(:json => not_expected)
      end

      it "should override as_json attributes on create" do
        result = standard_create
        expected = { :tasks => [{:done => true}], :projects => [{:name => 'project'}] }
        result.should include_json(:json => expected)
        not_expected = { :tasks => [{:title => "task"}], :projects => [{:description => "desc"}] }
        result.should_not include_json(:json => not_expected)
      end

      it "should override as_json attributes on update" do
        result = standard_update
        expected = { :tasks => [{:done => true}], :projects => [{:name => 'project'}] }
        result.should include_json(:json => expected)
        not_expected = { :tasks => [{:title => "task"}], :projects => [{:description => "desc"}] }
        result.should_not include_json(:json => not_expected)
      end
    end
  end

  context "params_accessible" do
    before do
      @klass = create_abstract_resource_class do
        def params_accessible(klass)
          { :projects => [:name], :tasks => [:title] }
        end
      end
    end

    it "should pass only params that are returned by params_accessible" do
      params = {
        :projects => [{:_local_id => '10', :name => 'SproutCore', :description => 'Great project'}],
        :tasks => [{:_local_id => '5', :title => 'My task', :done => true }]
      }
      controller = mock("controller", :params => params)
      Bulk::Resource.create(controller)
      p = Project.first
      p.name.should == "SproutCore"
      p.description.should be_nil

      t = Task.first
      t.title.should == "My task"
      t.done.should be_nil
    end

    context "with custom resource class" do
      before do
        tasks_class = Class.new(@klass) do
          resource_class Task
          resource_name :tasks

          def params_accessible(klass)
            { :tasks => [:done], :projects => [:description] }
          end
        end

        Object.const_set(:TaskResource, tasks_class)
      end

      after do
        Object.send(:remove_const, :TaskResource)
      end

      it "should run overriden params_accessible, only for current resource" do
        params = {
          :projects => [{:_local_id => '10', :name => 'SproutCore', :description => 'Great project'}],
          :tasks => [{:_local_id => '5', :title => 'My task', :done => true }]
        }
        controller = mock("controller", :params => params)
        result = Bulk::Resource.create(controller)
        p = Project.first
        p.name.should == "SproutCore"
        p.description.should be_nil

        # could not be saved, cause title is not in accessible
        Task.count.should == 0
      end
    end
  end

  context "params_protected" do
    before do
      @klass = create_abstract_resource_class do
        def params_protected(klass)
          { :projects => [:description], :tasks => [:done] }
        end
      end
    end

    it "should not pass any params returned by params_protected" do
      params = {
        :projects => [{:_local_id => '10', :name => 'SproutCore', :description => 'Great project'}],
        :tasks => [{:_local_id => '5', :title => 'My task', :done => true }]
      }
      controller = mock("controller", :params => params)
      Bulk::Resource.create(controller)
      p = Project.first
      p.name.should == "SproutCore"
      p.description.should be_nil

      t = Task.first
      t.title.should == "My task"
      t.done.should be_nil
    end

    context "with custom resource class" do
      before do
        tasks_class = Class.new(@klass) do
          resource_class Task
          resource_name :tasks

          def params_protected(klass)
            { :tasks => [:title], :projects => [:name] }
          end
        end

        Object.const_set(:TaskResource, tasks_class)
      end

      after do
        Object.send(:remove_const, :TaskResource)
      end

      it "should run overriden params_accessible, only for current resource" do
        params = {
          :projects => [{:_local_id => '10', :name => 'SproutCore', :description => 'Great project'}],
          :tasks => [{:_local_id => '5', :title => 'My task', :done => true }]
        }
        controller = mock("controller", :params => params)
        Bulk::Resource.create(controller)
        p = Project.first
        p.name.should == "SproutCore"
        p.description.should be_nil

        # could not be saved, cause title is protected
        Task.count.should == 0
      end
    end
  end

  context "authentication" do
    context "#authenticate_records" do
      before do
        @klass = create_abstract_resource_class do
          resources :tasks, :projects
          cattr_accessor :args, :actions, :result
          self.args = []
          self.actions = []
          self.result = true

          def authenticate_records(action, klass)
            self.class.actions << action
            self.class.args << klass.name
            self.class.result
          end
        end
      end

      it "should run before get request" do
        standard_get
        @klass.actions.should   == [:get] * 2
        @klass.args.sort.should == ["Project", "Task"]
      end

      it "should not fetch records that were not authenticated" do
        @klass.result = false
        result = standard_get
        json = {:json =>
          { :errors => {
              "tasks"    => { @task.id.to_s    => { "type" => "not_authenticated" } },
              "projects" => { @project.id.to_s => { "type" => "not_authenticated" } }
            }
          }
        }
        result.should include_json(json)
      end

      it "should run before create request" do
        standard_create
        @klass.actions.should   == [:create] * 2
        @klass.args.sort.should == ["Project", "Task"]
      end

      it "should not create records that were not authenticated" do
        @klass.result = false
        result = nil
        lambda {
          lambda {
            result = standard_create
          }.should_not change(Task, :count)
        }.should_not change(Project, :count)
        json = {:json =>
          { :errors => {
              "tasks"    => { '5'  => { "type" => "not_authenticated" } },
              "projects" => { '10' => { "type" => "not_authenticated" } }
            }
          }
        }
        result.should include_json(json)
      end

      it "should run before update request" do
        standard_update
        @klass.actions.should   == [:update] * 2
        @klass.args.sort.should == ["Project", "Task"]
      end

      it "should not update records that were not authenticated" do
        @klass.result = false
        result = standard_update
        json = {:json =>
          { :errors => {
              "tasks"    => { @task.id.to_s    => { "type" => "not_authenticated" } },
              "projects" => { @project.id.to_s => { "type" => "not_authenticated" } }
            }
          }
        }
        result.should include_json(json)
        @task.reload.title.should == 'My Task'
        @project.reload.name.should == 'SproutCore'
      end

      it "should run before delete request" do
        result = standard_delete
        @klass.actions.sort.should == [:delete] * 2
        @klass.args.sort.should    == ["Project", "Task"]
      end

      it "should not delete records that were not authenticated" do
        @klass.result = false
        result = nil
        lambda {
          lambda {
            result = standard_delete
          }.should change(Task, :count)
        }.should change(Project, :count)
        json = {:json =>
          { :errors => {
              "tasks"    => { @task.id.to_s    => { "type" => "not_authenticated" } },
              "projects" => { @project.id.to_s => { "type" => "not_authenticated" } }
            }
          }
        }
        result.should include_json(json)
      end
    end

    context "#authenticate_record" do
      before do
        @klass = create_abstract_resource_class do
          resources :tasks, :projects
          cattr_accessor :args, :actions, :result
          self.args = []
          self.actions = []
          self.result = true

          def authenticate_record(action, record)
            self.class.actions << action
            self.class.args << record
            self.class.result
          end
        end
      end

      it "should run during get request" do
        result = standard_get
        @klass.actions.should      == [:get] * 2
        @klass.args.map(&:id).sort == [@task.id, @project.id].sort
      end

      it "should not fetch records that were not authenticated" do
        @klass.result = false
        result = standard_get
        json = {:json =>
          { :errors => {
              "tasks"    => { @task.id.to_s    => { "type" => "not_authenticated" } },
              "projects" => { @project.id.to_s => { "type" => "not_authenticated" } }
            }
          }
        }
        result.should include_json(json)
      end

      it "should run during create request" do
        standard_create
        @klass.actions.sort.should == [:create, :create]
        @klass.args.map {|r| r.class.name}.sort.should == ["Project", "Task"]
      end

      it "should not create records that were not authenticated" do
        @klass.result = false
        result = nil
        lambda {
          lambda {
            result = standard_create
          }.should_not change(Task, :count)
        }.should_not change(Project, :count)
        json = {:json =>
          { :errors => {
              "tasks"    => { '5'  => { "type" => "not_authenticated" } },
              "projects" => { '10' => { "type" => "not_authenticated" } }
            }
          }
        }
        result.should include_json(json)
      end

      it "should run during update request" do
        standard_update
        @klass.actions.should   == [:update] * 2
        @klass.args.map { |r| r.class.name }.sort.should == ["Project", "Task"]
      end

      it "should not update records that were not authenticated" do
        @klass.result = false
        result = standard_update
        json = {:json =>
          { :errors => {
              "tasks"    => { @task.id.to_s    => { "type" => "not_authenticated" } },
              "projects" => { @project.id.to_s => { "type" => "not_authenticated" } }
            }
          }
        }
        result.should include_json(json)
        @task.reload.title.should == 'My Task'
        @project.reload.name.should == 'SproutCore'
      end

      it "should run during delete request" do
        standard_delete
        @klass.actions.should   == [:delete] * 2
        @klass.args.map { |r| r.class.name }.sort.should == ["Project", "Task"]
      end

      it "should not delete records that were not authenticated" do
        @klass.result = false
        result = nil
        lambda {
          lambda {
            result = standard_delete
          }.should change(Task, :count).by(1)
        }.should change(Project, :count).by(1)
        json = {:json =>
          { :errors => {
              "tasks"    => { @task.id.to_s    => { "type" => "not_authenticated" } },
              "projects" => { @project.id.to_s => { "type" => "not_authenticated" } }
            }
          }
        }
        result.should include_json(json)
      end
    end

    context "global authentication" do
      it "should run authentication callback before handling request" do
        abstract_resource = create_abstract_resource_class do
          cattr_accessor :authenticated
          self.authenticated = false

          def authenticate(action)
            self.class.authenticated = true
          end
        end

        controller = mock("controlelr", :params => {})
        result = Bulk::Resource.get(controller)
        abstract_resource.authenticated.should == true
        result[:status].should be_nil
      end

      it "should set 401 status if authentication fails" do
        abstract_resource = create_abstract_resource_class do
          def authenticate(action)
            false
          end
        end

        controller = mock("controlelr", :params => {})
        result = Bulk::Resource.get(controller)
        result[:status].should == 401
      end
    end
  end

  context "authorization" do
    context "#authorize_records" do
      before do
        @klass = create_abstract_resource_class do
          resources :tasks, :projects
          cattr_accessor :args, :actions, :result
          self.args = []
          self.actions = []
          self.result = true

          def authorize_records(action, klass)
            self.class.actions << action
            self.class.args << klass.name
            self.class.result
          end
        end

      end

      it "should run before get request" do
        standard_get
        @klass.actions.should   == [:get] * 2
        @klass.args.sort.should == ["Project", "Task"]
      end

      it "should not fetch records that were not authorized" do
        @klass.result = false
        result = standard_get
        json = {:json =>
          { :errors => {
              "tasks"    => { @task.id.to_s    => { "type" => "forbidden" } },
              "projects" => { @project.id.to_s => { "type" => "forbidden" } }
            }
          }
        }
        result.should include_json(json)
      end

      it "should run before create request" do
        standard_create
        @klass.actions.should   == [:create] * 2
        @klass.args.sort.should == ["Project", "Task"]
      end

      it "should not create records that were not authorized" do
        @klass.result = false
        result = nil
        lambda {
          lambda {
            result = standard_create
          }.should_not change(Task, :count)
        }.should_not change(Project, :count)
        json = {:json =>
          { :errors => {
              "tasks"    => { '5'  => { "type" => "forbidden" } },
              "projects" => { '10' => { "type" => "forbidden" } }
            }
          }
        }
        result.should include_json(json)
      end

      it "should run before update request" do
        standard_update
        @klass.actions.should   == [:update] * 2
        @klass.args.sort.should == ["Project", "Task"]
      end

      it "should not update records that were not authorized" do
        @klass.result = false
        result = standard_update
        json = {:json =>
          { :errors => {
              "tasks"    => { @task.id.to_s    => { "type" => "forbidden" } },
              "projects" => { @project.id.to_s => { "type" => "forbidden" } }
            }
          }
        }
        result.should include_json(json)
        @task.reload.title.should == 'My Task'
        @project.reload.name.should == 'SproutCore'
      end

      it "should run before delete request" do
        standard_delete
        @klass.actions.sort.should == [:delete] * 2
        @klass.args.sort.should    == ["Project", "Task"]
      end

      it "should not delete records that were not authorized" do
        @klass.result = false
        result = nil
        lambda {
          lambda {
            result = standard_delete
          }.should change(Task, :count).by(1)
        }.should change(Project, :count).by(1)
        json = {:json =>
          { :errors => {
              "tasks"    => { @task.id.to_s    => { "type" => "forbidden" } },
              "projects" => { @project.id.to_s => { "type" => "forbidden" } }
            }
          }
        }
        result.should include_json(json)
      end
    end

    context "#authorize_record" do
      before do
        @klass = create_abstract_resource_class do
          resources :tasks, :projects
          cattr_accessor :args, :actions, :result
          self.args = []
          self.actions = []
          self.result = true

          def authorize_record(action, record)
            self.class.actions << action
            self.class.args << record
            self.class.result
          end
        end
      end

      it "should run during get request" do
        standard_get
        @klass.actions.should      == [:get] * 2
        @klass.args.map(&:id).sort == [@task.id, @project.id].sort
      end

      it "should not fetch records that were not authorized" do
        @klass.result = false
        result = standard_get
        json = {:json =>
          { :errors => {
              "tasks"    => { @task.id.to_s    => { "type" => "forbidden" } },
              "projects" => { @project.id.to_s => { "type" => "forbidden" } }
            }
          }
        }
        result.should include_json(json)
      end

      it "should run during create request" do
        standard_create
        @klass.actions.sort.should == [:create, :create]
        @klass.args.map {|r| r.class.name}.sort.should == ["Project", "Task"]
      end

      it "should not create records that were not authorized" do
        @klass.result = false
        result = nil
        lambda {
          lambda {
            result = standard_create
          }.should_not change(Task, :count)
        }.should_not change(Project, :count)
        json = {:json =>
          { :errors => {
              "tasks"    => { '5'  => { "type" => "forbidden" } },
              "projects" => { '10' => { "type" => "forbidden" } }
            }
          }
        }
        result.should include_json(json)
      end

      it "should run during update request" do
        standard_update
        @klass.actions.should   == [:update] * 2
        @klass.args.map { |r| r.class.name }.sort.should == ["Project", "Task"]
      end

      it "should not update records that were not authorized" do
        @klass.result = false
        result = standard_update
        json = {:json =>
          { :errors => {
              "tasks"    => { @task.id.to_s    => { "type" => "forbidden" } },
              "projects" => { @project.id.to_s => { "type" => "forbidden" } }
            }
          }
        }
        result.should include_json(json)
        @task.reload.title.should == 'My Task'
        @project.reload.name.should == 'SproutCore'
      end

      it "should run during delete request" do
        standard_delete
        @klass.actions.should   == [:delete] * 2
        @klass.args.map { |r| r.class.name }.sort.should == ["Project", "Task"]
      end

      it "should not delete records that were not authorized" do
        @klass.result = false
        result = nil
        lambda {
          lambda {
            result = standard_delete
          }.should change(Task, :count).by(1)
        }.should change(Project, :count).by(1)
        json = {:json =>
          { :errors => {
              "tasks"    => { @task.id.to_s    => { "type" => "forbidden" } },
              "projects" => { @project.id.to_s => { "type" => "forbidden" } }
            }
          }
        }
        result.should include_json(json)
      end
    end

    context "global authorization" do
      it "should run authorization callback before handling request" do
        abstract_resource = create_abstract_resource_class do
          cattr_accessor :authorized
          self.authorized = false

          def authorize(action)
            self.class.authorized = true
          end
        end

        controller = mock("controlelr", :params => {})
        result = Bulk::Resource.get(controller)
        abstract_resource.authorized.should == true
        result[:status].should be_nil
      end

      it "should set 403 status if authentication fails" do
        abstract_resource = create_abstract_resource_class do
          def authorize(action)
            false
          end
        end
        Bulk::Resource.abstract_resource_class = abstract_resource

        controller = mock("controlelr", :params => {})
        result = Bulk::Resource.get(controller)
        result[:status].should == 403
      end
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
      create_abstract_resource_class
    end

    it "should skip resources that can't be resolved into classes" do
      lambda {
        controller = mock("controller", :params => { :tasks => [1], :todos => [2] })
        Bulk::Resource.get(controller)
      }.should_not raise_error
    end
  end

  describe "subclassed resource" do
    before do
      TaskResource = Class.new(AbstractResource)
      TaskResource.resource_class Task
      controller = mock("controller", :params => {})
      @resource = TaskResource.new(controller)
    end

    after do
      Object.send(:remove_const, :TaskResource)
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
