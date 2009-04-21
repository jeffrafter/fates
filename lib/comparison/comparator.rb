# See README for Copyright and License information 

module FateSearch # :nodoc:
  module Comparison # :nodoc:  
    # Handles comparison of strings. Additionally, external strings can be
    # prepared in a similar fashion, which allows for bulk sorting
    class Comparator    
      def prepare(field) 
        k = $KCODE
        $KCODE = ''      
        field.downcase
      ensure
        $KCODE = k    
      end
      
    end
  end  
end  
  
