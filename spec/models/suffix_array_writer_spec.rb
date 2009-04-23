require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../init'

describe :suffix_array_writer do
  
  before :all do
    @sample_path = File.dirname(__FILE__) + '/../samples/suffixes_test'
    @analyzers = [FateSearch::Analysis::WhitespaceAnalyzer.new]
  end

  it "should use default options when creating a new suffix array writer when no initialization options are included" do
    @w = FateSearch::SuffixArrayWriter.new
    @w.instance_variable_get('@block_size').should == 32
    @w.instance_variable_get('@inline_suffix_size').should == 8
    @w.instance_variable_get('@finished').should be_false
  end  
  
  it "should use initialization options when creating a new suffix array writer" do
    @w = FateSearch::SuffixArrayWriter.new(:block_size => 1, :inline_suffix_size => 2, :path => @sample_path)
    @w.instance_variable_get('@block_size').should == 1
    @w.instance_variable_get('@inline_suffix_size').should == 2
    @w.instance_variable_get('@path').should == @sample_path
  end  
  
  it "should append a suffix" do
    @w = FateSearch::SuffixArrayWriter.new
    @w.add_suffixes(FateSearch::Analysis::WhitespaceAnalyzer.new, "suffixB suffixA", 1)
    @w.instance_variable_get('@suffixes').should == [1, 9]
  end
  
=begin  
  it "should sort and dump the suffixes when finished" do
    @w = FateSearch::SuffixArrayWriter.new
    @f = FateSearch::FulltextWriter.new
    @f.add_document(1, {:sample_field => 'suffixB suffixA'}, @field_map, @field_infos, @w, @m)
    @f.finish!
    @w.instance_variable_get('@suffixes').should == [16, 24]
    @w.finish!(@f.data)
    @w.instance_variable_get('@suffixes').should == [24, 16]
    @w.data.should == "\002\000\000\000 \000\000\000\b\000\000\000suffixA\000\000\000\000\000\000\000\000\000\000\000\000\000\030\000\000\000\020\000\000\000"
  end
=end  

end