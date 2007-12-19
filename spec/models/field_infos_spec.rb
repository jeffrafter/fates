require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../init'

describe :field_infos do

  before :each do
    @f = FTSearch::FieldInfos.new
  end
  
  it "should be able to add field information" do
    @f.add_field(:name => :test)
    @f[:test].should_not be_nil
  end  
  
  it "should use default options when creating a new field when no initialization options or options parameter are included" do
    @f.add_field(:name => :test)
    options = @f[:test]
    options[:analyzer].class.should == FTSearch::Analysis::WhitespaceAnalyzer
    options[:stored].should == true
  end  
  
  it "should use initialization options when creating a new field when no options parameter is included" do
    @f = FTSearch::FieldInfos.new(:analyzer => FTSearch::Analysis::SimpleIdentifierAnalyzer.new, :stored => false)
    @f.add_field(:name => :test)
    options = @f[:test]
    options[:analyzer].class.should == FTSearch::Analysis::SimpleIdentifierAnalyzer
    options[:stored].should === false
  end  
  
  it "should use submitted options when creating a new field" do
    @f.add_field(:name => :test, :analyzer => FTSearch::Analysis::SimpleIdentifierAnalyzer.new, :stored => false)
    options = @f[:test]
    options[:analyzer].class.should == FTSearch::Analysis::SimpleIdentifierAnalyzer
    options[:stored].should === false
  end  
  
  it "should create a new field with default options when it can't find the field" do
    options = @f[:test]
    options[:analyzer].class.should == FTSearch::Analysis::WhitespaceAnalyzer
    options[:stored].should == true
  end
end

