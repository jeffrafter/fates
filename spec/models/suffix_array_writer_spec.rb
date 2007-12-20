require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../init'

describe :suffix_array_writer do
  
  before :all do
    @sample_path = File.dirname(__FILE__) + '/../samples/suffixes_test'
    @field_map = Hash.new{|h,k| h[k.to_sym] = h.size}
    @field_map[:uri]
    @field_infos = FTSearch::FieldInfos.new
    @field_infos.add_field(:name => :sample_field)
  end

  it "should use default options when creating a new suffix array writer when no initialization options are included" do
    @w = FTSearch::SuffixArrayWriter.new
    @w.instance_variable_get('@block_size').should == 32
    @w.instance_variable_get('@inline_suffix_size').should == 8
    @w.instance_variable_get('@finished').should be_false
  end  
  
  it "should use initialization options when creating a new suffix array writer" do
    @w = FTSearch::SuffixArrayWriter.new(:block_size => 1, :inline_suffix_size => 2, :path => @sample_path)
    @w.instance_variable_get('@block_size').should == 1
    @w.instance_variable_get('@inline_suffix_size').should == 2
    @w.instance_variable_get('@path').should == @sample_path
  end  
  
  it "should append a suffix" do
    @w = FTSearch::SuffixArrayWriter.new
    @w.add_suffixes(FTSearch::Analysis::WhitespaceAnalyzer.new, "suffixB suffixA", 1)
    @w.instance_variable_get('@suffixes').should == [1, 9]
  end
  
  it "should sort and dump the suffixes when finished" do
    @w = FTSearch::SuffixArrayWriter.new
    @m = FTSearch::DocumentMapWriter.new
    @f = FTSearch::FulltextWriter.new
    @f.add_document(1, {:sample_field => 'suffixB suffixA'}, @field_map, @field_infos, @w, @m)
    @f.finish!
    @w.instance_variable_get('@suffixes').should == [16, 24]
    @w.finish!(@f.data)
    @w.instance_variable_get('@suffixes').should == [24, 16]
    @w.data.should == "\002\000\000\000 \000\000\000\b\000\000\000suffixA\000\000\000\000\000\000\000\000\000\000\000\000\000\030\000\000\000\020\000\000\000"
  end

  it "should merge the suffixes from a suffix array reader" do
    @w = FTSearch::SuffixArrayWriter.new
    @m = FTSearch::DocumentMapWriter.new
    @f = FTSearch::FulltextWriter.new
    @f.add_document(1, {:sample_field => 'suffixB suffixA'}, @field_map, @field_infos, @w, @m)
    @f.finish!
    @w.finish!(@f.data)
    io = @w.io
    io.seek(0, 0)
    lambda {@w.merge(FTSearch::SuffixArrayReader.new(@f, :io => io))}.should raise_error
    
    io.seek(0, 0)
    @w2 = FTSearch::SuffixArrayWriter.new
    @w2.merge(FTSearch::SuffixArrayReader.new(@f, :io => io))
    @w2.instance_variable_get('@suffixes').should == [24, 16]
    @w2.finish!(@f.data)
    @w2.data.should == @w.data
  end
  

end