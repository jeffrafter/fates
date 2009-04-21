# See README for Copyright and License information 

module FateSearch # :nodoc:
  module Analysis # :nodoc:
    # Analyzers are used to break down text into suffixes. The base +Analyzer+
    # is not intended for direct use and will not find any suffixes. Instead
    # create a +WhitespaceAnalyzer+ or +SimpleIdentifierAnalyzer+, or build 
    # a custom analyzer descendent that responds to +append_suffixes+ 
    class Analyzer      
      # Override +append_suffixes+ in descendent classes to fill the array
      # and return it with the appropriate suffixes
      def append_suffixes(array, text, offset, base_offset, index); end      
    end
  end
end 
