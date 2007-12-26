require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../init'

describe :whitespace_analyzer do
  
  before :all do
    @a = FateSearch::Analysis::WhitespaceAnalyzer.new
  end

  it "should not append suffixes for blank text" do
    @a.append_suffixes([], "", 0).should == []
  end  

  it "should append one suffix when there is no whitespace" do
    @a.append_suffixes([], "test", 0).should == [0]
  end  
  
  it "should append multiple suffixes when there are spaces" do
    @a.append_suffixes([], "test1 test2  test3", 0).should == [0, 6, 13]
  end  
  
  it "should append multiple suffixes when there are tabs" do
    @a.append_suffixes([], "test1\ttest2\t test3", 0).should == [0, 6, 13]
  end  

  it "should append multiple suffixes when there are new lines" do
    @a.append_suffixes([], "test1\ntest2\n test3", 0).should == [0, 6, 13]
  end  
  
  it "should append multiple suffixes when there are carriage returns" do
    @a.append_suffixes([], "test1\rtest2\r\ntest3", 0).should == [0, 6, 13]
  end  
  
  it "should return suffixes that start at the specified offset" do
    @a.append_suffixes([], "test", 10).should == [10]
  end  

  
end