# See README for Copyright and License information

require 'in_memory_writer'

module FateSearch # :nodoc:
  # FulltextWriter allows you to store field information and data in an input/output
  # stream, that can be referenced in a suffix array reader and suffix array writer.
  class FulltextWriter 
    include InMemoryWriter
   
    # Read-only path. If the +FulltextWriter+ was created with a :path option,
    # the path will be relfected here, otherwise the path will be nil and the 
    # +FulltextWriter+ will use an in memory buffer.
    attr_reader :path

    # Create a new +FulltextWriter+. You can pass the path option to write the
    # full text field information to a file, otherwise the path will be nil and 
    # the +FulltextWriter+ will use an in memory buffer. In windows/dos, the 
    # file will be written to in binary mode.
    #
    # Valid options:
    # [<tt>:path</tt>] The file that the full text field information will be written to.
    def initialize(options = {})
      @path = options[:path]
      if @path
        @io = File.open(@path, "wb")
      else
        initialize_in_memory_buffer
        @io = @memory_io
      end
    end

    # Use a full text reader to initialize the data in this writer. This 
    # operation can happen before or after records have been added to the 
    # writer.
    def merge(fulltext_reader)
      fulltext_reader.dump_data do |data|
        @io.write data  
      end
    end

    # Add the field information for an entry to the fulltext data file. The 
    # +id+ uniquely identifies this entry and correlates the to identifier
    # used in the fragment, suffix and map writers. The +field_hash+ contains
    # a hash of the fields and values that will be stored for the record. 
    # The key for each field in the hash should match the key used when creating
    # fields in the field_infos.
    def add(primary_key, fields, analyzers, suffix_array_writer)
      base_offset = @io.pos
      write_header(primary_key, fields)
      1.upto(fields.size) {|i|
        data = fields[i] || ''
        suffix_offset = store_field(data)
        suffix_array_writer.add_suffixes(analyzers[i], data, suffix_offset) if analyzers[i]
      }  
      write_footer((@io.pos-base_offset)+5)
    end

    # Write a trailing null character and close the file.
    def finish!
      @io.write "\0"
      if (@path)
        @io.fsync
        @io.close
      end  
    end
    
  private
  
    # Write the total size of the record (for seeking) as a single long. To 
    # calculate the total size, select all of the fields from the fields array
    # and sum the field data size and field header size. Also write the 
    # +primary_key+ for lookups later
    def write_header(primary_key, fields)
      total_size = fields.inject(0){|sum,field| sum += (field || '').size}
      @io.write [total_size, primary_key].pack("VV") 
    end

    # Write a leading null and the size of the record (for seeking) as a 
    # single long. 
    def write_footer(size)
      @io.write [size].pack("V")
      @io.write "\0"
    end
        
    # Write the field to the current input/output stream. Each field will be 
    # stored with a header that contains the field size (as longs) followed
    # by the +data+ for the field (the actual text or value) and a trailing \0.
    # This function returns the offset to the start of the offset of the field 
    # header in the input/output stream.
    def store_field(data)
      @io.write [data.size].pack("V") 
      offset = @io.pos
      @io.write data
      @io.write "\0"
      offset 
    end
  end
end
