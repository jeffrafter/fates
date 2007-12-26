# See README for Copyright and License information

require 'comparison/comparator'

module FateSearch # :nodoc:

  # Read the suffixes that were read from the full text and find matches for
  # search terms (or phrases). The matches can be returned as a +Hit+ or as
  # a +Hits+ enumeration that can be read sequentially. 
  class SuffixArrayReader

    # A hit is a structure that represents single match for a term. The structure
    # contains the term, the index of the term in the suffix array, the offset of
    # the term inthe fulltext and the fulltext reader.
    class Hit < Struct.new(:term, :index, :offset, :fulltext_reader)

      # The context of the hit. This will grab the textual information from the
      # full text reader on either side of the match up to +size+.
      def context(size)
        strip_markers(self.fulltext_reader.get_data(offset - size, 2 * size), size)
      end

      # The text for the hit. In general the +size+ should be the actual length 
      # of the textual data or term that was matched.
      def text(size)
        strip_markers(self.fulltext_reader.get_data(offset, size), 0)
      end    
    private
      
      # Fields in the full text rader are delimited with null characters. These
      # markers are stripped from +str+ up to the specified +size+
      def strip_markers(str, size)
        first = (str.rindex("\0", -size) || -1) + 1
        last  = str.index("\0", size) || str.size
        str[first...last]
      end
    end

    # The +Hits+ class is an enumeration for +Hit+ objects. The +Hits+ object
    # never actually creates all of the +Hit+ structures at once. Instead it 
    # lazily creates an object when stepping through the each method or the
    # array based lookup. The structure is built for a specific term, the start
    # index and end index in the suffix array, the fulltext reader and the 
    # suffix array reader used to lookup the offsets.
    class Hits < Struct.new(:term, :from_index, :to_index, :fulltext_reader, :suffix_array_reader)
      include Enumerable
      
      def each
        term = self.term
        fulltext = self.fulltext_reader
        suffix_array = self.suffix_array_reader
        self.from_index.upto(self.to_index - 1) do |index|
          yield Hit.new(term, index, suffix_array.index_to_offset(index), fulltext)
        end
      end

      def [](index)
        index += self.size if index < 0
        index = from_index + index
        if index < to_index && index >= from_index
          Hit.new(self.term, index, self.suffix_array_reader.index_to_offset(index), self.fulltext_reader)
        else
          nil
        end
      end

      def size
        to_index - from_index
      end
    end
    
    class Suffixes
      attr_reader :size
      attr_reader :base
    
      def initialize(io, size)
        @suffixes_io = io        
        @base = io.pos
        @size = size
      end
      
      def [](index)
        # 4 = size of a single long, the suffixes are a sequence of longs that 
        # represent offsets into the fulltext
        @suffixes_io.pos = @base + index * 4
        @suffixes_io.read(4).unpack("V")[0]
      end
    end

    def initialize(fulltext_reader, options = {})
      @comparator = FateSearch::Comparison::Comparator.new
      @fulltext_reader = fulltext_reader
      unless options[:path] || options[:io]
        raise ArgumentError, "Need either the path to the suffix array file or an input/output stream."
      end
      init_internal_structures(options)
    end

    def count_hits(term)
      prepared_term = @comparator.prepare(term)
      suffix_index = binary_search(prepared_term, 0, @suffixes.size)
      offset = @suffixes[suffix_index]
      if @comparator.prepare(@fulltext_reader.get_data(offset, term.size)) == prepared_term
        to = binary_search_upper(prepared_term, 0, @suffixes.size)
        to - suffix_index
      else
        0
      end
    end

    def find_all(term)
      prepared_term = @comparator.prepare(term)
      suffix_index = binary_search(prepared_term, 0, @suffixes.size)
      offset = @suffixes[suffix_index]
      if @comparator.prepare(@fulltext_reader.get_data(offset, term.size)) == prepared_term
        to = binary_search_upper(prepared_term, 0, @suffixes.size)
        Hits.new(term, suffix_index, to, @fulltext_reader, self)
      else
        Hits.new(term, 0, 0, @fulltext_reader, self)
      end
    end

    def find_first(term)
      prepared_term = @comparator.prepare(term)
      suffix_index = binary_search(prepared_term, 0, @suffixes.size)
      offset = @suffixes[suffix_index]
      if @comparator.prepare(@fulltext_reader.get_data(offset, term.size)) == prepared_term
        Hit.new(term, suffix_index, offset, @fulltext_reader)
      else
        nil
      end
    end

    def find_next(hit)
    end

    def index_to_offset(suffix_index)
      @suffixes[suffix_index]
    end

    def hits_to_offsets(hits)
      # 4 = size of a single long, the suffixes are a sequence of longs that 
      # represent offsets into the fulltext
      from = hits.from_index
      to   = hits.to_index
      @io.pos = @suffixes.base + 4 * from
      @io.read((to - from) * 4).unpack("V*")
    end

    def dump_data
      @io.pos = @suffixes.base
      while data = @io.read(32768)
        yield data.unpack("V*")
      end
    end

  private
  
    def init_internal_structures(options)
      # setup io
      if options[:path]
        @io = File.open(options[:path], "rb")
      else
        @io = options[:io]
      end
      
      # read header
      @total_suffixes, @block_size, @inline_suffix_size = @io.read(12).unpack("VVV")
      @inline_suffixes = []
      if @block_size != 0
        0.step(@total_suffixes, @block_size) { @inline_suffixes << @io.read(@inline_suffix_size) }
      end

      # skip padding
      if (mod = @io.pos & 0xf) != 0
        @io.read(16 - mod)
      end

      # load the suffixes
      @suffixes = Suffixes.new(@io, @total_suffixes)
    end

    def binary_search(term, from, to)
      from, to = binary_search_inline_suffixes(term, from, to)
      tsize = term.size
      while from < to
        middle = (from + to) / 2
        pivot = @comparator.prepare(@fulltext_reader.get_data(@suffixes[middle], tsize))
        if term <= pivot
          to = middle
        else
          from = middle + 1
        end
      end
      from
    end

    def binary_search_upper(term, from, to)
      from, to = binary_search_inline_suffixes_upper(term, from, to)      
      tsize = term.size
      while from < to
        middle = (from + to) / 2
        pivot = @comparator.prepare(@fulltext_reader.get_data(@suffixes[middle], tsize))
        if term < pivot # upper does not include pivot
          to = middle
        else
          from = middle + 1
        end
      end
      from
    end


    def binary_search_inline_suffixes(term, from, to)    
      return [from, to] if @block_size == 0
      tsize = term.size
      while to - from > @block_size
        middle = (from + to) / 2
        quotient, mod = middle.divmod(@block_size)
# TODO, verify why this line occasionally causes infinite loops
#       middle = middle - mod
        pivot = @comparator.prepare(@inline_suffixes[quotient])
        if tsize <= @inline_suffix_size
          if term <= pivot
            to = middle
          else
            from = middle + 1
          end
        elsif term[0, @inline_suffix_size] < pivot # should this be <= ?
          to = middle
        else
          pivot = pivot.clone
          pivot[-1] += 1
          if term > pivot
            from = middle + 1
          else 
            pivot = @comparator.prepare(@fulltext_reader.get_data(@suffixes[middle], term.size))
            if term <= pivot
              to = middle
            else
              from = middle + 1
            end
          end
        end
      end
      [from, to]
    end

    def binary_search_inline_suffixes_upper(term, from, to)
      return [from, to] if @block_size == 0
      tsize = term.size
      while to - from > @block_size
        middle = (from + to) / 2
        quotient, mod = middle.divmod(@block_size)
# TODO, verify why this line occasionally causes infinite loops
#       middle = middle - mod
        pivot = @comparator.prepare(@inline_suffixes[quotient])
        if tsize <= @inline_suffix_size
          if term < pivot[0, tsize] # upper does not include pivot
            to = middle
          else
            from = middle + 1
          end
        elsif term[0, @inline_suffix_size] < pivot
          to = middle
        else
          pivot = pivot.clone
          pivot[-1] += 1
          if term > pivot
            from = middle + 1
          else 
            pivot = @comparator.prepare(@fulltext_reader.get_data(@suffixes[middle], term.size))
            if term < pivot # upper does not include pivot
              to = middle
            else
              from = middle + 1
            end
          end
        end
      end
      [from, to]
    end
  end
end  
