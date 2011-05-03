require 'spec_helper'

describe Bulk::AbstractCollection do
  let(:collection) { Bulk::AbstractCollection.new }
  let(:item) { Object.new }

  it "should be empty" do
    collection.should be_empty
  end

  specify "#add(id, item) should add item" do
    collection.set('1', item)
    collection.get('1').should == item
  end

  specify "#remove(id) should remove item" do
    collection.set('1', item)
    collection.delete('1')
    collection.should be_empty
  end

  specify "#clear should clear the collection" do
    collection.set('1', item)
    collection.clear
    collection.should be_empty
  end

  specify "#get(id) should get the item with given id" do
    collection.set('1', item)
    collection.get('1').should == item
  end

  it "should work with both strings and fixnums" do
    second_item = Object.new
    collection.set(1, item)
    collection.set('2', second_item)
    collection.get('1').should == item
    collection.get(2).should == second_item
    collection.delete(2)
    collection.length.should == 1
    collection.get(1).should == item
  end

  it "should return number of items" do
    collection.set(1, item)
    collection.set(2, item)
    collection.length.should == 2
  end

  specify "#exists?(id) should check if given item exists" do
    collection.set(1, item)
    collection.exists?(1)
  end

  specify "#ids should return item ids" do
    second_item = Object.new
    collection.set(1, item)
    collection.set(10, second_item)
    collection.ids.sort.should == ['1', '10']
  end
end
