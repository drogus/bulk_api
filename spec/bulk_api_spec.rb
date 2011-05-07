require 'spec_helper'

describe "Bulk API" do
  it "should set app/bulk path" do
    Rails.application.paths["app/bulk"].first.should == Rails.root.join("app/bulk")
  end

  it "should set app/sproutcore path" do
    Rails.application.paths["app/sproutcore"].first.should == Rails.root.join("app/sproutcore")
  end
end
