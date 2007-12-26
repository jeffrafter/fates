# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#

require 'strscan'
require 'ftsearch/analysis/analyzer'

module FTSearch # :nodoc:
  module Analysis # :nodoc:
    
    # Basic identifier analysis. Attempts to split a section of text based on 
    # simple identifier rules. See +append_suffixes+ for more information
    class SimpleIdentifierAnalyzer < Analyzer
      
      # Checks the text for identifiers that start with letter, followed by
      # letters or numbers or an underscore. Each match is stored as an index 
      # to the suffix.
      def append_suffixes(array, text, offset)
        sc = StringScanner.new(text)
        sc.skip(/[^A-Za-z_]+/)
        until sc.eos?
          array << (sc.pos + offset)
          break unless sc.skip(/[A-Za-z_][A-Za-z0-9_]*[^A-Za-z_]*/)
        end
        array
      end
    end
  end #  Analyzer
end  # FTSearch
