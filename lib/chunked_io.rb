module FateSearch
  class ChunkedIo

    def self.open(path, mode, size = 1024)
      self.new(:base_path => path, :file_mode => mode, :chunk_size => size)
    end    

    def initialize(options)
      @file_mode = options[:file_mode]
      @base_path = options[:base_path]
      @chunk_size = options[:chunk_size] || 1024
      @chunks = []
      @io = nil
      @offset = -1
    end
    
    def read(size)  
      data = ''
      loop do
        break unless size && size > 0
        next_chunk if @io.nil? || @io.pos >= @chunk_size
        size_available = @chunk_size - @io.pos
        read_size = size <= size_available ? size : size_available
        data += @io.read(read_size)
        size -= read_size
      end
      data
    end
    
    def getc
      read 1
    end
    
    def pos=(val)
      open_chunk(val / @chunk_size)
      @io.pos = val % @chunk_size
    end

    def pos
      return 0 unless @io
      @io.pos + (@chunk_size * @offset)
    end  
    
    def write(data)
      data = data.dup
      loop do
        break unless data && data != ''
        next_chunk if @io.nil? || @io.pos >= @chunk_size
        space_available = @chunk_size - @io.pos
        data_to_write = data.slice!(0, space_available)
        @io.write data_to_write
      end
    end
    
    def fsync
      @chunks.each {|io| 
        next unless io
        io.fsync
      }
    end
    
    def close
      @chunks.each {|io| 
        next unless io
        io.close
      }
    end  
    
  private  
    def close_chunk(chunk)
      io = @chunks[chunk]
      return if io.nil? || io.closed?
      # Can't fsync a read stream
      io.fsync rescue nil
      io.close
      @chunks[chunk] = nil
    end
    
    def open_chunk(chunk)
      close_chunk(@offset) unless @offset == -1 || @offset == chunk
      @offset = chunk
      @io = @chunks[@offset]
      unless @io
        path = @base_path + "/" + ("%08d" % @offset)
        FileUtils.mkdir_p @base_path
        @io = File.open(path, @file_mode)    
        @chunks[@offset] = @io
      end
    end
    
    def next_chunk    
      open_chunk(@offset + 1)
    end
    
  end
end  