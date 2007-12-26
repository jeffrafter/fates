# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#

require 'strscan'
require 'ftsearch/analysis/analyzer'

module FTSearch # :nodoc:
  module Analysis # :nodoc:
    
    # Basic text analysis. Attempts to split a section of text based on 
    # basic whitespace rules. See +append_suffixes+ for more information
    class WhitespaceAnalyzer < Analyzer

      # Split the text into suffix offsets and push them into the array. The suffixes
      # should be split by whitespace boundaries and not include the whitespace.
      def append_suffixes(array, text, offset)
        sc = StringScanner.new(text)
        sc.skip(/(\s|\n)*/)
        until sc.eos?
          array << (sc.pos + offset)
          break unless sc.skip(/\S+\s*/)
        end
        array
      end
    end
  end #  Analyzer
end  # FTSearch
