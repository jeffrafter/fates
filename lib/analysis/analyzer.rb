# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#

module FTSearch # :nodoc:
  module Analysis # :nodoc:
    # Analyzers are used to break down text into suffixes. The base +Analyzer+
    # is not intended for direct use and will not find any suffixes. Instead
    # create a +WhitespaceAnalyzer+ or +SimpleIdentifierAnalyzer+, or build 
    # a custom analyzer descendent that responds to +append_suffixes+ 
    class Analyzer
      
      # Find the suffixes for a block of text and return them as an array
      def find_suffixes(text)
        append_suffixes([], text, 0)
      end

      # Override +append_suffixes+ in descendent classes to fill the array
      # and return it with the appropriate suffixes
      def append_suffixes(array, text, offset); end
      
    end
  end # Analysis
end # FTSearch
