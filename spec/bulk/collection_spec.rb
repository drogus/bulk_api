require 'spec_helper'

describe Bulk::Collection do
  let(:collection) { Bulk::Collection.new }
  let(:record) { Object.new }

  it "should be empty" do
    collection.should be_empty
  end

  specify "#add(id, record) should add record" do
    collection.set('1', record)
    collection.get('1').should == record
  end

  specify "#remove(id) should remove record" do
    collection.set('1', record)
    collection.delete('1')
    collection.should be_empty
  end

  specify "#clear should clear the collection" do
    collection.set('1', record)
    collection.clear
    collection.should be_empty
  end

  specify "#get(id) should get the record with given id" do
    collection.set('1', record)
    collection.get('1').should == record
  end

  it "should work with both strings and fixnums" do
    second_record = Object.new
    collection.set(1, record)
    collection.set('2', second_record)
    collection.get('1').should == record
    collection.get(2).should == second_record
    collection.delete(2)
    collection.length.should == 1
    collection.get(1).should == record
  end

  it "should return number of records" do
    collection.set(1, record)
    collection.set(2, record)
    collection.length.should == 2
  end

  specify "#exists?(id) should check if given record exists" do
    collection.set(1, record)
    collection.exists?(1)
  end

  specify "#ids should return record ids" do
    second_record = Object.new
    collection.set(1, record)
    collection.set(10, second_record)
    collection.ids.sort.should == ['1', '10']
  end

  context "errors" do
    before do
      collection.set(1, record)
    end

    specify "#set(id, error) should add error for record with given id" do
      collection.errors.set(1, :invalid)
      collection.errors.get(1).type.should == :invalid
    end

    specify "#delete(id) should delete error for given id" do
      collection.errors.set(1, :invalid)
      collection.errors.get(1).type.should == :invalid
      collection.errors.delete(1)
      collection.errors.get(1).should == nil
    end

    it "should raise error on attempt to modify errors for not existing record" do
      no_such_record = Bulk::Collection::Errors::NoSuchRecord
      lambda { collection.errors.set(2, :forbidden) }.should raise_error(no_such_record)
      lambda { collection.errors.delete(2) }.should raise_error(no_such_record)
      lambda { collection.errors.get(2) }.should raise_error(no_such_record)
    end
  end
end
