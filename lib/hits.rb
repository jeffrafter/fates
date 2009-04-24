module FateSearch # :nodoc:

  # The +Hits+ class is an enumeration for +Hit+ objects. The +Hits+ object
  # never actually creates all of the +Hit+ structures at once. Instead it 
  # lazily creates an object when stepping through the each method or the
  # array based lookup. The structure is built for a specific term, the start
  # index and end index in the suffix array, the fulltext reader and the 
  # suffix array reader used to lookup the offsets.
  class Hits < Struct.new(
    :term, 
    :from_index, 
    :to_index, 
    :fulltext_reader, 
    :suffix_array_reader)
    include Enumerable
    
    def [](index)
      index += self.size if index < 0
      index = from_index + index
      if index < to_index && index >= from_index
        info = suffix_array_reader.index_to_info(index)
        return {:term => term, 
                :index => index, 
                :offset => info[0], 
                :record_offset => info[1], 
                :field_id => info[2], 
                :fulltext_reader => fulltext_reader}
      end
      nil
    end

    def size
      to_index - from_index
    end
  end
end