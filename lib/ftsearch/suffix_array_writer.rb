# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#

require 'enumerator'
require 'ftsearch/in_memory_writer'

module FTSearch # :nodoc:
  # Class that allows you to append a list of suffixes to an array and write it
  # to a specified file or in memory buffer.
  class SuffixArrayWriter
    include InMemoryWriter

    DEFAULT_OPTIONS = {
      :block_size => 32,
      :inline_suffix_size => 8
    }
    
    # Create a new +SuffixArrayWriter+ and pass in options. If you do not include
    # specific options the defaults will be used.
    #
    # Valid options:
    # [<tt>:path</tt>] The path of the stored suffixes array. If no path is included the array will use an in-memory buffer
    # [<tt>:block_size</tt>] The size of blocks for writing (default 32)
    # [<tt>:inline_suffix_size</tt>] The storage size for each suffix (default 8)
    def initialize(options = {})
      options             = DEFAULT_OPTIONS.merge(options)
      @path               = options[:path]
      @suffixes           = []
      @block_size         = options[:block_size]
      @inline_suffix_size = options[:inline_suffix_size]
      @finished           = false
      @need_sort          = false
      initialize_in_memory_buffer
    end

    # Load the data from an existing suffix array prior to adding suffixes using
    # +merge+. You must pass in an existing +SuffixArrayReader+ and the current
    # +SuffixArrayWriter+ cannot have any suffix information.
    def merge(suffix_array_reader)
      raise "SuffixArrayWriter must be empty to merge data from another reader" unless @suffixes.empty?
      suffix_array_reader.dump_data do |partial_sarray|
        @suffixes.concat partial_sarray
      end
    end

    # Add suffixes to the existing array. The +analyzer+ is used to parse the
    # +data+ to find the suffixes and append the offsets to the internal array.
    # The +offset+ is the starting offset of the +data+ in the source text.
    def add_suffixes(analyzer, data, offset)
      @need_sort = true
      analyzer.append_suffixes(@suffixes, data, offset)
    end

    # Sort and dump the suffixes to suffix file specified in the path or to the
    # in memory buffer. The +fulltext+ will be used to dump the inline suffixes,
    # and should match the data that was used in building the suffixes. It can
    # be the output of the data method on a +FulltextWriter+. This method is 
    # usually called by a +FragmentWriter+.
    def finish!(fulltext)
      return if @finished
      sort!(fulltext)
      dump_suffixes(fulltext)
      @finished = true
    end

  private

    # Writes the suffixes to the file specified in the path or to the in memory
    # buffer. If writing to a file, the file will be truncated. On windows/dos
    # the file will be written in binary mode. The suffixes file will contain
    # three longs in the header, followed by the inline suffix blocks, followed
    # by a pad to get to the 16-byte (I think this is for improved file system
    # speed when writing?) followed by the actual suffix array.
    def dump_suffixes(fulltext)
      io = @path ? File.open(@path, "wb") : @memory_io
      # Number of suffixes, block size for each suffix, 
      io.write([@suffixes.size, @block_size || 0, @inline_suffix_size].pack("VVV")) # TODO three sequential longs, could be V3
      dump_inline_suffixes(io, fulltext) if @block_size && @block_size > 0
      add_padding(io)
      dump_suffix_array(io)
    ensure
      io.close if @path
    end

    # Dump the inline suffixes to the current input/output stream. The data is
    # written as a null padded ascii string which is +inline_suffix_size+ long.
    def dump_inline_suffixes(io, fulltext)
      0.step(@suffixes.size, @block_size) do |suffix_idx|
        io.write([fulltext[@suffixes[suffix_idx], @inline_suffix_size]].pack("a#{@inline_suffix_size}"))
      end
    end

    # Write the suffixes in slices (for filesystem speed?). The suffixes are 
    # written as a series of longs.
    def dump_suffix_array(io)
      @suffixes.each_slice(1024){|suffixes| io.write(suffixes.pack("V*")) }
    end

    # Add additional padding (nulls, \0) to the 16-byte
    def add_padding(io)
      if (mod = io.pos & 0xf) != 0
        io.write("\0" * (16 - mod))
      end
    end

    # Sort the suffixes based on text in the fulltext. This sorts from the
    # suffix offset to the end of the data in the full text stream? It is 
    # possible that no sort is needed if the data was merged but no additional
    # suffixes were added (which assumes the merged data was pre sorted)
    def sort!(fulltext)
      return unless @need_sort
      tsize = fulltext.size # TODO check this size versus 40
      @suffixes = @suffixes.sort_by{|offset| fulltext[offset, tsize - offset]}
    end
  end
end  # FTSearch
