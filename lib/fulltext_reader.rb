# See README for Copyright and License information

require 'chunked_io'

module FateSearch
  class FulltextReader

    def initialize(options = {})
      raise ArgumentError, "Need the path to the suffix array file" unless options[:path]
      @io = ChunkedIo.open(options[:path], "rb")
    end

    def get_data(offset, size)
      @io.pos = offset[0]
      @io.read(size)
    end
          
    # Gets the record start position and the size and reads the block
    def offset_to_record_data(offset)
      record_start, size = offset_to_record_start(offset)
      get_data(record_start, size)
    end  
    
    def hit_to_record_data(hit)
      @io.pos = hit.record_offset
      size = @io.read(4).unpack("V")[0]
      @io.pos = hit.record_offset
      @io.read(size)
    end  
    
    def get_primary_key(data_block)
      # Primary key is the second offset in the header, stored as a long
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
        
    def rank_offsets(hits, weights, term, limit = 10, compare_size = false)
      scores = Hash.new{|h,k| h[k] = 0.0}
      current = hits.size
      size = term.size.to_f
      percent_diff = 1
      hits.each {|hit|
        # TODO, could maybe add one more number, the suffix size, into the array
        if (compare_size)
          @io.pos = hit.offset
          true while @io.getc != 0
          text_size = @io.pos - hit.offset
          diff = (size - text_size).abs
          percent_diff = 1 - (diff / size)
        end  
        scores[hit.record_offset] += (weights[hit.field_id] * percent_diff) + current
        current -= 1
      }
      sorted_offsets = scores.sort_by{|offset,score| -score}
      # Return the results as data blocks
      blocks = []
      0.upto(limit-1) {|index|
        break if index >= sorted_offsets.size
        offset, score = sorted_offsets[index]
        @io.pos = offset
        size = @io.read(4).unpack("V")[0]
        @io.pos = offset
        data = @io.read(size)        
        blocks << [get_primary_key(data), get_fields(data), score]
      }  
      blocks
    end

  private
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
          @io.pos = @io.pos + size
        end
      end        
      [record_start, size]
    end  
  end
end
