require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../init'

describe :simple_identifier_analyzer do
  
  before :all do
    @a = FateSearch::Analysis::SimpleIdentifierAnalyzer.new
  end

  it "should not append suffixes for blank text" do
    @a.append_suffixes([], "", 0).should == []
  end  

  it "should append one suffix when there is one identifier" do
    @a.append_suffixes([], "test", 0).should == [0]
    @a.append_suffixes([], "Test", 0).should == [0]
    @a.append_suffixes([], "Test39", 0).should == [0]
    @a.append_suffixes([], "Test_39", 0).should == [0]
    @a.append_suffixes([], "_test", 0).should == [0]
  end  
  
  it "should append multiple suffixes when there are breaking characters" do
    @a.append_suffixes([], "test1 test2", 0).should == [0, 6]
    @a.append_suffixes([], "test1?test2", 0).should == [0, 6]
  end  
  
  it "should not append suffixes for invalid identifiers" do
    @a.append_suffixes([], "1", 0).should == []
    @a.append_suffixes([], "$@!", 0).should == []
  end  

  it "should return suffixes that start at the specified offset" do
    @a.append_suffixes([], "test", 10).should == [10]
  end  
  
end