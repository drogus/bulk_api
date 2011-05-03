require 'spec_helper'

describe Bulk::Collection do
  let(:collection) { Bulk::Collection.new }
  let(:item) { Object.new }

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
