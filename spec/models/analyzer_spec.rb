require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../init'

describe :analyzer do
  
  it "should not find any suffixes by default" do
    a = FateSearch::Analysis::Analyzer.new
    a.find_suffixes("this is a sample bit of text").should be_nil
  end  
  
end