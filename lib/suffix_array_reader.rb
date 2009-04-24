# See README for Copyright and License information

require 'comparison/comparator'
require 'suffixes'
require 'hits'

module FateSearch # :nodoc:

  # Read the suffixes that were read from the full text and find matches for
  # search terms (or phrases). The matches can be returned as a +Hit+ or as
  # a +Hits+ enumeration that can be read sequentially. 
  class SuffixArrayReader
    
    def initialize(fulltext_reader, options = {})
      @shard_size = options[:shard_size] || 4
      @comparator = FateSearch::Comparison::Comparator.new
      @fulltext_reader = fulltext_reader
      raise ArgumentError, "Need the path to the suffix array file" unless options[:path] 
      @base_path = options[:path]
      @cache = {}
      @lookups = {}
    end
    
    def count(term)
      region = lookup(term)
      region[1] - region[0]
    end

    def find(term)
      region = lookup(term)     
      Hits.new(term, region[0], region[1], @fulltext_reader, self)
    end

    # Don't call these directly!

    def lookup(term)
      prepared_term = @comparator.prepare(term)
      region = @lookups[prepared_term]
      return region if region
      return @lookups[prepared_term] = [0, 0] unless prepare(prepared_term)
      from = binary_search(prepared_term, 0, @suffixes.size, false)
      offset = index_to_offset(from)
      data = @fulltext_reader.get_data(offset, term.size)
      if @comparator.prepare(data) == prepared_term
        to = binary_search(prepared_term, 0, @suffixes.size, true)
        return @lookups[prepared_term] = [from, to]
      end
      @lookups[prepared_term] = [0, 0]
    end
  
    def index_to_offset(suffix_index)
      @suffixes.offset(suffix_index)
    end

    def index_to_info(suffix_index)
      @suffixes[suffix_index]
    end

  protected

    # Eventually I should make this not suck
    def prepare(term)
      shard = term.gsub(/(\0|\s|\n)/, '').slice(0, @shard_size)
      raise "Search term must be at least #{@shard_size} characters" unless shard.size >= @shard_size
      path = @base_path + '/' + shard

      # Look for a cached version            
      if item = @cache[path]
        @io = item[:io]
        @total_suffixes = item[:total_suffixes]         
        @block_size = item[:block_size]
        @inline_suffix_size = item[:inline_block_size]
        @inline_suffixes = item[:inline_suffixes]
        @suffixes = item[:suffixes]      
        return false
      end
      
      # Not in cache, lets build it and cache it
      begin
        @io = File.open(path, "rb")
      rescue
        return false
      end 
       
      read_header_and_suffixes        
      @cache[:path] = {
        :io => @io, 
        :total_suffixes => @total_suffixes,
        :block_size => @block_size,
        :inline_suffix_size => @inline_suffix_size,
        :inline_suffixes => @inline_suffixes,
        :suffixes => @suffixes
      }
      return true
    end

  private
  
    def read_header_and_suffixes
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

    def binary_search(term, from, to, upper)
      from, to = binary_search_inline_suffixes(term, from, to, upper)
      tsize = term.size
      while from < to
        middle = (from + to) / 2
        pivot = @comparator.prepare(@fulltext_reader.get_data(@suffixes.offset(middle), tsize))
        if (!upper && term <= pivot) || (upper && term < pivot)
          to = middle
        else
          from = middle + 1
        end
      end
      from
    end

    def binary_search_inline_suffixes(term, from, to, upper)    
      return [from, to] if @block_size == 0
      tsize = term.size
      while to - from > @block_size
        middle = (from + to) / 2
        quotient, mod = middle.divmod(@block_size)
        pivot = @comparator.prepare(@inline_suffixes[quotient])
        if tsize <= @inline_suffix_size
          if (!upper && term <= pivot) || (upper && term < pivot[0, tsize])
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
            pivot = @comparator.prepare(@fulltext_reader.get_data(@suffixes.offset(middle), tsize))
            if (!upper && term <= pivot) || (upper && term < pivot)
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
