require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../init'

describe :document_map_writer do
  
  before :all do
    @sample_path = File.dirname(__FILE__) + '/samples/map_test'
  end

  it "should use a file stream if created with a path option when finished" do
    @w = FTSearch::DocumentMapWriter.new(:path => @sample_path)
    @w.add_document(1, "A")
    @w.finish!
    File.open(@sample_path, "rb"){|f| f.read}.should == @w.data
  end  
  
  it "should add a document" do
    @w = FTSearch::DocumentMapWriter.new
    @w.add_document(1, "A")
    @w.instance_variable_get('@uri_tbl').length.should == 2
    @w.finish!
    @w.data.should == "\004\b[\a[\a0\"\006A[\000"
  end
  
  it "should add a field" do
    @w = FTSearch::DocumentMapWriter.new
    @w.add_field(0, 1, 2, 3)
    @w.instance_variable_get('@field_arr').length.should == 1
    @w.finish!
    @w.data.should == "\004\b[\a[\000[\006[\ti\000i\006i\ai\b"
  end  
  
  it "should merge the map from a document map reader" do
    @w = FTSearch::DocumentMapWriter.new
    @w.add_document(1, "A")
    @w.add_field(0, 1, 2, 3)
    @w.finish!
    @w.data.should == "\004\b[\a[\a0\"\006A[\006[\ti\000i\006i\ai\b"    
  
    io = @w.io  
    io.seek(0, 0)
    reader = FTSearch::DocumentMapReader.new(:io => io)  
    writer = FTSearch::DocumentMapWriter.new
    writer.merge(reader)
  
    uri_tbl = writer.instance_variable_get('@uri_tbl')
    field_arr = writer.instance_variable_get('@field_arr')
    uri_tbl[1].should == "A"
    field_arr[0].should == [0, 1, 2, 3]
  end  
  
end