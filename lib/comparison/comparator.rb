# See README for Copyright and License information 

module FateSearch # :nodoc:
  module Comparison # :nodoc:
  
    # Handles comparison of strings. Additionally, external strings can be
    # prepared in a similar fashion, which allows for bulk sorting
    # TODO, eliminate class methods in favor of instance methods and allow
    # TODO, comparators to be passed into the fragment writer as an option
    # TODO, allow chaining of comparators?
    class Comparator
    
      def exclusive_compare(left, right)
        left < right
      end
    
      def inclusive_compare(left, right)
        left <= right
      end
    
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
  
