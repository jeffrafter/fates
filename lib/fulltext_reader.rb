# See README for Copyright and License information

module FateSearch
  class FulltextReader
    DEFAULT_OPTIONS = {
      :path => nil,
      :io   => nil,
    }
    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      unless options[:path] || options[:io]
        raise ArgumentError, "Need either the path to the suffix array file or an input/output stream."
      end
      init_internal_structures(options)
    end

    def get_data(offset, size)
      @io.pos = offset
      @io.read(size)
    end
          
    # Gets the record start position and the size and reads the block
    def offset_to_record_data(offset)
      record_start, size = offset_to_record_start(offset)
      get_data(record_start, size)
    end  
    
    def get_primary_key(data_block)
      # Header: 8 == total field data size, primary key
      primary_key = data_block[4..7].unpack("V")[0]
    end

    def get_fields(data_block)
      # Header: 8 == total field data size, primary key
      header_size = 8
      footer_size = 5
      size = data_block.size
      fields = []
      field_start = header_size
      while field_start <= size - (header_size + footer_size)
        # Fields are structured: data size, data, \0
        field_size = data_block[(field_start)..(field_start+3)].unpack("V")[0] 
        fields << data_block[(field_start+4)..(field_start+4+field_size-1)]
        field_start += field_size + 5 
      end
      fields
    end
        
    def rank_offsets_by_fragment(offsets, weights, limit = 10)
      # Convert the offset positions into record markers
      h = Hash.new{|h,k| h[k] = 0.0}
      sizes = Hash.new
      record_offsets = offsets.map{|offset| offset_to_record_start(offset) }   
      record_offsets.each {|record_offset|
        h[record_offset[0]] += 1 / record_offset[1]  
        sizes[record_offset[0]] ||= record_offset[1]   
      }
      # Sort based on the scores (key, value)
      sorted_offsets = h.sort_by{|offset,score| -score}
      # Return the results as data blocks
      blocks = []
      0.upto(limit-1) {|index|
        break if index >= sorted_offsets.size
        offset, score = sorted_offsets[index]
        size = sizes[offset]
        @io.seek(offset, IO::SEEK_SET)
        data = @io.read(size)        
        blocks << [get_primary_key(data), get_fields(data)]
      }  
      blocks
    end

    def rank_offsets(offsets, weights)
      scores = Hash.new{|h,k| h[k] = 0.0}
      fields = Hash.new
      keys = Hash.new
      # Convert the offset positions into record start and size markers
      # The record_offsets array will correllate directly with offsets
      record_offsets = offsets.map{|offset| offset_to_record_start(offset) }   
      record_offsets.each_with_index {|record_offset, index|
        start, size = record_offset
        record_fields = nil
        # Memoize the fields so we seek and read as little as possible
        unless (fields.has_key?(start))
          @io.seek(start, IO::SEEK_SET)
          data = @io.read(size)
          record_fields = get_fields(data)
          fields[start] = record_fields
          keys[start] = get_primary_key(data)
        end  
        # Score the documents
        offset = offsets[index]
        field_index, field_size = offset_to_field_info(offset, start, record_fields || fields[start])        
        score = weights[field_index] / field_size  
        scores[start] += score
      }      
      # Sort based on the scores (key, value)
      sorted_offsets = scores.sort_by{|start,score| -score}
      # Return the results as key, fields blocks
      sorted_offsets.map {|start,score| [keys[start], fields[start]] } 
    end

    def rank_offsets_probabilistic(offsets, weights, limit = 10)
      iterations = 50 * Math.sqrt(offsets.size)
      h = Hash.new{|h,k| h[k] = 0.0}
      sizes = Hash.new
      record_offsets = offsets.map{|offset| offset_to_record_start(offset) }   
      max = record_offsets.size
      while iterations > 0
        start, size = record_offsets[rand(max)]
        # See note in rank_offsets
        h[start] += 1 / size
        sizes[start] ||= size
        iterations -= 1
      end
      # Sort based on the scores (key, value)
      sorted_offsets = h.sort_by{|offset,score| -score}
      # Return the results as data blocks
      blocks = []
      0.upto(limit-1) {|index|
        break if index >= sorted_offsets.size
        offset, score = sorted_offsets[index]
        size = sizes[offset]
        @io.seek(offset, IO::SEEK_SET)
        data = @io.read(size)        
        blocks << [get_primary_key(data), get_fields(data)]
      }  
      blocks
    end
            
    def dump_data(&block)
      blocksize = 32768
      @io.pos = 0
      begin
        size = @io.stat.size - 1
      rescue NoMethodError # try with StringIO's interface
        size = @io.string.size - 1
      end
      read = 0
      while read < size
        data = @io.read([size - read, blocksize].min)
        read += data.size
        yield data
      end      
    end

  private
    def init_internal_structures(options)
      if options[:path]
        @io = File.open(options[:path], "rb")
      else
        @io = options[:io]
      end
    end

    
    # TODO this could be replaced with a single seek to the index in a record map
    # Instead of passing offset, the suffix index would be compared to the map
    # A simpler solution is to double the size of the suffix array and store the
    # record start (and possily a single byte for field index?) It is likely there
    # is a better construction for a number relative to the suffix offset so it 
    # would not need to be a four-byte long
    def offset_to_record_start(offset)
      # Read to the end of the data (from the offset) which is marked by a footer
      # Footer: \0
      @io.pos = offset      
      # Which is faster? this or @io.gets("\0")
      true while @io.getc != 0
      
      # Repeatedly loop through the fields to the record footer
      while true       
        # Read the size, it may be the record size, or subsequent field
        size = @io.read(4).unpack("V")[0]
        c = @io.getc
        # If the size is followed by a null then it is the record footer 
        # Unless the size is 0, then it is just an empty field
        if (c == 0 && size != 0)          
          end_pos = @io.pos
          record_start = (end_pos-size)          
          break
        else
          # Not a null, skip the field data (and trailing null)
          @io.seek(size, IO::SEEK_CUR)
        end
      end        
      [record_start, size]
    end  

    def offset_to_field_info(offset, start, fields)
      offset_from_start = offset - start
      pos = 8
      fields.each_with_index { |field, index|
        size = field.size + 5
        if pos + size > offset_from_start
          return [index, size]
        end
        pos += size
      }
      return [nil, nil]
    end

  end
end
