require 'fileutils'
require 'analysis/whitespace_analyzer'

module FateSearch #:nodoc:

  class FateSearchError < StandardError; end

  module Extensions #:nodoc: 
        
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      
      def fatesearch(options = {})
        include_fatesearch
        self.fatesearch_path = options[:path]
        self.fatesearch_key = options[:key]
        self.fatesearch_fields = options[:fields]
        self.fatesearch_weights = options[:weights]
        self.fatesearch_default_sorting = options[:scoring]
        self.fulltext_index if options[:index]
        self.fulltext_load
      end

      def include_fatesearch
        return if self.included_modules.include?(FateSearch::Extensions::InstanceMethods)
        include FateSearch::Extensions::InstanceMethods        
        class_eval do
          cattr_accessor :fatesearch_path
          cattr_accessor :fatesearch_key
          cattr_accessor :fatesearch_fields
          cattr_accessor :fatesearch_weights
          cattr_accessor :fatesearch_default_sorting
          cattr_accessor :fragment_writer
          cattr_accessor :fulltext_reader
          cattr_accessor :suffix_array_reader
          extend FateSearch::Extensions::SingletonMethods
        end
      end
    end

    module InstanceMethods
    end
    
    module SingletonMethods
      def fulltext_count(query)
        fulltext_load unless self.fulltext_reader
        self.suffix_array_reader.count_hits(query)
      end
      
      def fulltext_find(query, offset = nil, limit = nil)
        fulltext_load unless self.fulltext_reader
        offset ||= 0
        if (offset == 0 && limit == 1)
          hits = [self.suffix_array_reader.find_first(query)]
        else
          hits = self.suffix_array_reader.find_all(query)            
        end
        fulltext_data = []
        if hits && hits.size > 0
          limit = hits.size unless limit
          if self.fatesearch_default_sorting 
            self.fatesearch_weights ||= Array.new(self.fatesearch_fields.size, 100000)
            sorted = self.fulltext_reader.rank_offsets(hits, self.fatesearch_weights, query, offset+limit)
            offset.upto((offset+limit)-1) { |i| 
              if i < sorted.size 
                fulltext_data << sorted[i]
              end  
            }  
          else  
            offset.upto((offset+limit)-1) { |i| 
              if i < hits.size 
                record_data = self.fulltext_reader.hit_to_record_data(hits[i]) 
                primary_key = self.fulltext_reader.get_primary_key(record_data) 
                fields = self.fulltext_reader.get_fields(record_data) 
                fulltext_data << [primary_key, fields, 0]
              end  
            }  
          end
        end  
        fulltext_data
      end
        
      def fulltext_index      
        puts "Building indexes for #{self.fatesearch_path}"
        white_space = FateSearch::Analysis::WhitespaceAnalyzer.new
        analyzers = Array.new(self.fatesearch_fields.size, white_space)
        path = self.fatesearch_path
        raise "Invalid base path" if path.empty? || path == '/' 
        FileUtils.rm_rf path
        self.fragment_writer = FateSearch::FragmentWriter.new(:path => path, :analyzers => analyzers)
        puts "Reading records for #{self.fatesearch_path}"
        records = self.find(:all, :select => "#{self.fatesearch_key}," + self.fatesearch_fields.join(','))
        puts "Indexing records for #{self.fatesearch_path}"
        records.each {|row|
          key = row[self.fatesearch_key]
          values = self.fatesearch_fields.map{|field| row[field]}
          puts values.inspect
          self.fragment_writer.add(key, values) 
        }          
        puts "Writing indexes for #{self.fatesearch_path}"
        self.fragment_writer.finish!
        puts "Indexes built for #{self.fatesearch_path}"
      end

      def fulltext_load
        latest = Dir[self.fatesearch_path].sort.last
        self.fulltext_reader = FateSearch::FulltextReader.new(:path => "#{latest}/fulltext")
        self.suffix_array_reader = FateSearch::SuffixArrayReader.new(self.fulltext_reader, :path => "#{latest}/suffixes")
      end
    end    
  end  
end
