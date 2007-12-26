# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#

require 'ftsearch/in_memory_writer'

module FTSearch # :nodoc:
  # Class that allows you to create a set of mappings from document ids 
  # (sequential array indexes in the full text) to document indentifiers and 
  # write it to a specified file or in memory buffer. The identifers can be 
  # document URIs or database record ids or any other kind of identifier.  
  class DocumentMapWriter
    include InMemoryWriter

    # Create a new +DocumentMapWriter+ and pass in options.
    #
    # Valid options:
    # [<tt>:path</tt>] The path of the stored document map array. If no path is included the array will use an in-memory buffer
    def initialize(options = {})
      @path      = options[:path]
      @field_arr = []
      @uri_tbl   = []
      @data      = [@uri_tbl, @field_arr]
      initialize_in_memory_buffer
    end

    # Load the data from an existing document map prior to adding new mappings 
    # using +merge+. You must pass in an existing +DocumentMapReader+ which will
    # overwrite the current +DocumentMapWriter+ information.
    def merge(doc_map_reader)
      @uri_tbl, @field_arr = doc_map_reader.dump_data
      @data = [@uri_tbl, @field_arr]
    end

    # Add a document mapping. The +doc_id+ should be an index in the fulltext.
    # For example, if the document id is 1 the length of the +uri_table+ will
    # be 2 because it is an array and not a hash.
    def add_document(doc_id, uri)
      @uri_tbl[doc_id] = uri
    end

    # Add a field size mapping. The +doc_id+ should be an index in the fulltext.
    def add_field(offset, doc_id, field_id, size)
      @field_arr << [offset, doc_id, field_id, size]
    end

    # Write the fields and identifier mappings to a new file if a path was 
    # included in the options when creating this +DocumentMapWriter+, otherwise
    # write the data to an in memory buffer. The file will replace any existing
    # file and if the file is written on windows/dos it will be written in 
    # binary mode. 
    def finish!
      if @path
        File.open(@path, "wb") do |f|
          Marshal.dump(@data, f)
        end
      else
        Marshal.dump(@data, @memory_io)
      end
    end
  end
end  # FTSearch
