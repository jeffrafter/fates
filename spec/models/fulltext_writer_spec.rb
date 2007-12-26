require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../init'

describe :fulltext_writer do

=begin
  before :all do
    @sample_path = File.dirname(__FILE__) + '/../samples/fulltext_test'
    @field_map = Hash.new{|h,k| h[k.to_sym] = h.size}
    @field_map[:uri]
    @field_infos = FTSearch::FieldInfos.new
    @field_infos.add_field(:name => :primary_key, :stored => false)
    @field_infos.add_field(:name => :sample_field)
  end
  
  before :each do
    @suffix_array_writer = FTSearch::SuffixArrayWriter.new
    @map_writer = FTSearch::DocumentMapWriter.new
  end

  it "should use a file stream if created with a path option" do
    @w = FTSearch::FulltextWriter.new(:path => @sample_path)
    @w.add_document(1, {:primary_key => 1, :sample_field => 'A'}, @field_map, @field_infos, @suffix_array_writer, @map_writer)
    @w.finish!
    File.open(@sample_path, "rb"){|f| f.read}.should == @w.data
  end  
  
  it "should add a document" do
    @w = FTSearch::FulltextWriter.new
    @w.add_document(1, {:primary_key => 1, :sample_field => 'A'}, @field_map, @field_infos, @suffix_array_writer, @map_writer)
    @w.finish!
    @w.data.should == "\n\000\000\000\001\000\000\000\001\000\000\000\001\000\000\000A\000\000"
  end
  
  it "should create a document mapping when the document is added" do
    @w = FTSearch::FulltextWriter.new
    @w.add_document(1, {:uri => '1', :primary_key => 1, :sample_field => 'Z'}, @field_map, @field_infos, @suffix_array_writer, @map_writer)
    @map_writer.instance_variable_get('@uri_tbl')[1].should == '1'
    @map_writer.instance_variable_get('@field_arr')[0].should == [8, 1, 0, 1] # offset, index, field_index, size
  end
  
  it "should store the field information and write the suffixes when the document is added" do
    @w = FTSearch::FulltextWriter.new
    @w.add_document(1, {:primary_key => 1, :sample_field => 'suffixB suffixA'}, @field_map, @field_infos, @suffix_array_writer, @map_writer)
    @suffix_array_writer.instance_variable_get('@suffixes').should == [16, 24]
  end  
  
  it "should merge the fulltext from a fulltext reader" do
    @w = FTSearch::FulltextWriter.new
    @w.add_document(1, {:primary_key => 1, :sample_field => 'A'}, @field_map, @field_infos, @suffix_array_writer, @map_writer)
    @w.finish!
    io = @w.io
    io.seek(0, 0)
    @w2 = FTSearch::FulltextWriter.new
    @w2.merge(FTSearch::FulltextReader.new(:io => io))
    @w2.finish!
    @w2.data.should == "\n\000\000\000\001\000\000\000\001\000\000\000\001\000\000\000A\000\000"
  end  
=end    
end