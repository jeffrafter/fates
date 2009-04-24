module FateSearch # :nodoc:
  class Suffixes
    attr_reader :size
  
    def initialize(io, size)
      @suffixes_io = io        
      @base = io.pos
      @size = size
    end
    
    def [](index)
      @suffixes_io.pos = @base + index * 12
      @suffixes_io.read(12).unpack("VVV")
    end
    
    def offset(index)
      # 4 = size of a single long, the suffixes are a sequence of longs that 
      # represent offsets into the fulltext
      @suffixes_io.pos = @base + index * 12
      @suffixes_io.read(4).unpack("V")      
    end
  end
end