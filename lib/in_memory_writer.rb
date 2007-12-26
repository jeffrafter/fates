# See README for Copyright and License information

require 'stringio'

module FateSearch # :nodoc:
  module InMemoryWriter # :nodoc:

    # Create the buffer
    def initialize_in_memory_buffer
      @memory_io = StringIO.new("")
    end
    
    # Retrieve the memory stream or File input output stream
    def io
      if @path
        File.open(@path, "rb") rescue nil
      else
        @memory_io
      end
    end
    
    # Determine where or not the stream is a memory stream
    def memory?
      @path.nil?
    end
    
    # Retieve the path, which may be nil
    def path
      @path
    end          
        
    # When pulling data from a class that includes the in memory writer, it will
    # either use the internal memory buffer or load from the file if the 
    # @path instance variable exists. Note, on windows/dos the file will be read
    # in binary read only mode.
    def data
      if @path
        File.open(@path, "rb"){|f| f.read} rescue nil
      else
        @memory_io.string.clone
      end
    end        
  end
end  
