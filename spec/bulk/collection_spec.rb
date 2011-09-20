require 'spec_helper'

describe Bulk::Collection do
  let(:collection) { Bulk::Collection.new }
  let(:item) { mock("item", :id => 3, :as_json => "item_3_as_json") }

  it "should not allow to modify as_json_options" do
    class << item
      def as_json(options)
        options[:foo] = "baz"
      end
    end

    collection.set(1, item)
    as_json_options = {:foo => "bar"}
    hash = collection.to_hash(:items, :as_json_options => as_json_options)

    as_json_options[:foo].should == "bar"
  end

  it "applies as_json options to the records" do
    item.should_receive(:as_json).with({ :only => [:something] }).and_return({:something => "something"})
    collection.set(1, item)
    hash = collection.to_hash(:items, :as_json_options => {:only => [:something]})
  end

  it "can be converted to hash" do
    collection.set(1, item)
    collection.errors.set(1, :invalid, :y => {:so => :serious})

    second_item = mock("second item", :as_json => "item_4_as_json", :id => 4)
    collection.set(2, second_item)

    expected = {
      :items => ["item_4_as_json"],
      :errors => {:items => { '1' => { :type => :invalid, :data => { :y => { :so => :serious } } } } }
    }
    hash = collection.to_hash(:items)
    hash.should include_json(expected)
    hash.should_not include(:items => [item])
  end

  it "can be converted to hash with only ids" do
    collection.set(1, item)
    collection.errors.set(1, :invalid, :y => {:so => :serious})

    second_item = mock("second item", :as_json => "item_4_as_json", :id => 4)
    collection.set(2, second_item)

    expected = {
      :items => [4],
      :errors => {:items => { '1' => { :type => :invalid, :data => { :y => { :so => :serious } } } } }
    }
    hash = collection.to_hash(:items, :only_ids => true)
    hash.should include_json(expected)
    hash.should_not include(:items => [3])
  end

  context "errors" do
    before do
      collection.set(1, item)
    end

    specify "#set(id, error) should add error for item with given id" do
      collection.errors.set(1, :invalid)
      collection.errors.get(1).type.should == :invalid
    end

    specify "#delete(id) should delete error for given id" do
      collection.errors.set(1, :invalid)
      collection.errors.get(1).type.should == :invalid
      collection.errors.delete(1)
      collection.errors.get(1).should == nil
    end

    it "should save error with given data" do
      collection.errors.set(1, :invalid, :y => {:so => :serious})
      collection.errors.get(1).type.should == :invalid
      collection.errors.get(1).data.should == {:y => {:so => :serious}}
    end
  end
end
