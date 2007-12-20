# Original Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#

require 'ftsearch/in_memory_writer'

module FTSearch # :nodoc:
  # FulltextWriter allows you to store field information and data in an input/output
  # stream, that can be referenced in a document map and suffix array writer.
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
    # operation can happen before or after documents have been added to the 
    # writer.
    def merge(fulltext_reader)
      fulltext_reader.dump_data do |data|
        @io.write data  
      end
    end

    # Add the field information for an entry to the fulltext data file. The 
    # +id+ uniquely identifies this entry and correlates the to identifier
    # used in the fragment, suffix and map writers. The +field_hash+ contains
    # a hash of the fields and values that will be stored for the document. 
    # The key for each field in the hash should match the key used when creating
    # fields in the field_infos.
    def add_document(id, field_hash, field_mapping, field_infos, suffix_array_writer, map_writer)
      write_document_header(id, field_hash, field_mapping, field_infos)
#      map_writer.add_document(id, field_hash[:uri])
      primary_key = field_hash[:primary_key] || 0
      field_hash.each_pair do |field_name, data|
        if field_id = field_mapping[field_name]
          field_info = field_infos[field_name]
          if field_info[:stored]
            suffix_offset, segment_offset = store_field(primary_key, field_id, data)
            if analyzer = field_info[:analyzer]
              suffix_array_writer.add_suffixes(analyzer, data, suffix_offset)
            end
#            map_writer.add_field(segment_offset, id, field_id, data.size)
          end
        end
      end
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
  
    # Write the total size of the document (for seeking) as a single long. To 
    # calculate the total size, select all of the fields from the document hash
    # that will be stored, and sum the field data size and field header size.
    def write_document_header(doc_id, doc_hash, field_mapping, field_infos)
      stored_fields = doc_hash.select do |field_name, data|
        field_infos[field_name][:stored]
      end
      # 9 == field ids plus data size plus trailing \0
      field_header_size = 9
      total_size = stored_fields.inject(0){|s,(_,data)| s + data.size}
      total_size += stored_fields.size * field_header_size
      @io.write [total_size].pack("V") # pack the size as a long
    end

    # Write the field to the current input/output stream. Each field will be 
    # stored with a header that contains the doc_id, field_id, and size (as longs) followed
    # by the data for the field (the actual text or value) and a trailing \0.
    # This function returns an array containing the offset to the start of 
    # the data, and the offset of the field header in the input/output stream.
    def store_field(primary_key, field_id, data)
      @io.write [primary_key, field_id, data.size].pack("V3") # pack the array as three longs
      offset = @io.pos
      @io.write data
      @io.write "\0"
      @io.write [primary_key, field_id, data.size].pack("V3") # pack the array as three longs
      @io.write "\0"
      [offset, offset - 12] # start of data, start of header (header size is 12)
    end
  end
end  # FTSearch
