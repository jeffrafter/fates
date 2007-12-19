require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../init'

class TempSpecWriter 
  include FTSearch::InMemoryWriter

  attr_accessor :path   

  def write(data)
    @memory_io.write(data)
  end
end  

describe :in_memory_writer do
  
  before :all do
    @sample_path = File.dirname(__FILE__) + '/samples/in_memory_writer_test'
  end
  
  before :each do
    @w = TempSpecWriter.new    
  end

  it "should retrieve data from the path" do 
    @w.path = @sample_path
    @w.data.should == "test"
  end  
  
  it "should retrieve data from memory" do
    @w.initialize_in_memory_buffer
    @w.write("test")
    @w.data.should == "test"
    @w.io.class.should == StringIO
    @w.memory?.should be_true
  end  
  
  it "should return the path and a file stream" do
    @w.path = @sample_path
    @w.path.should == @sample_path    
    @w.io.class.should == File
    @w.memory?.should be_false
  end
  
end