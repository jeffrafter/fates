# See README for Copyright and License information 
require File.expand_path(File.dirname(__FILE__) + '/../init')

FATE_PATH = ENV['FATE_PATH'] || File.expand_path(File.dirname(__FILE__) + "/../index/fates")
BASE_PATH = ENV['BASE_PATH'] || File.expand_path(File.dirname(__FILE__) + "/../index/fates/contacts")

namespace :fates do
  desc "Randomize the contacts"
  task :randomize do
    require 'fastercsv'
    sample_path = File.expand_path(File.dirname(__FILE__) + "/../spec/samples/contacts.csv")
    puts "Reading contacts"
    rows = FasterCSV.read(sample_path)
    puts "Writing contacts"
    num_documents = 0
    File.open(sample_path, "w") { |f|
      1.upto(50000) {
        f.write "#{num_documents += 1},\"#{rows[rand(rows.size)][1] || ''}\",\"#{rows[rand(rows.size)][2] || ''}\"\n" 
      }  
    }  
  end

  desc "Index the sample contacts for the fate search plugin"
  task :index do
    require 'fileutils'
    require 'fastercsv'
    require 'lib/analysis/whitespace_analyzer'
    sample_path = File.expand_path(File.dirname(__FILE__) + "/../spec/samples/contacts.csv")
    
    # Protect against rm -rf /
    puts "Invalid base path" && return if BASE_PATH.empty? || BASE_PATH == '/' || FATE_PATH.empty? || FATE_PATH == '/'
    
    puts "Removing the current index for contacts"
    t1 = Time.new
    FileUtils.rm_rf FATE_PATH 
    
    puts "Preparing fields"
    t2 = Time.new
    white_space = FateSearch::Analysis::WhitespaceAnalyzer.new
    analyzers = [white_space, white_space]

    puts "Reading contacts"
    t3 = Time.new
    rows = FasterCSV.read(sample_path)
    
    puts "Indexing contacts"
    t4 = Time.new
    fragment  = FateSearch::FragmentWriter.new(:path => "#{BASE_PATH}-0000000", :analyzers => analyzers)
    rows.each {|row| fragment.add(row[0].to_i, [row[2], row[1]]) }

    puts "Writing indexes"
    t5 = Time.new
    fragment.finish!
    
    puts "Done"
    t6 = Time.new
    
    puts "Needed #{t2-t1} to remove the current indexes."
    puts "Needed #{t4-t3} to read the contacts file."
    puts "Needed #{t5-t4} to index the contacts."
    puts "Needed #{t6-t5} to write the indexes."
    puts "Total time: #{Time.new - t1}"
    puts "Total records: #{rows.size}"
  end
  
  desc "Search the contacts in the fate search plugin QUERY='find this' COUNT='no'"
  task :search do
    q = ENV['QUERY']
          
    # Probabilistic sorting is useful for large data sets
    default_sorting = ENV['SORT'] == 'y'

    # Lookup the most recent index files
    latest = Dir["#{BASE_PATH}-*"].sort.last

    puts "Loading the index files"
    t1 = Time.new
    fulltext_reader = FateSearch::FulltextReader.new(:path => "#{latest}/fulltext")
    suffix_array_reader = FateSearch::SuffixArrayReader.new(fulltext_reader, :path => "#{latest}/suffixes")
    
    unless ENV['COUNT'] == 'no'
      count_time = Time.new
      puts "Counting the number of hits"
      puts "Total hits: #{suffix_array_reader.count_hits(q)} (#{Time.new - count_time})"      
    end  

    puts "Looking up all matches"
    t2 = Time.new
    hits = suffix_array_reader.find_all(q)            
    t3 = Time.new
    show_all = ENV['ALL'] == 'yes'
    if hits && hits.size > 0
      if default_sorting 
        # Build a weight table for ranking (initialize for nudging certain fields)
        weights = [20000000, 100000000] # :first_name, :last_name
        sorted = fulltext_reader.rank_offsets(hits, weights, q)
        puts "Showing #{sorted.size <= 10 || show_all ? 'all' : 'top 10'} matches of #{sorted.size}:"
        count = sorted.size > 10 && show_all ? sorted.size : 10
        0.upto(count) { |i| 
          if i < sorted.size 
            primary_key, fields, score = sorted[i]
            p "#{primary_key}: #{fields.join(' ')}, (#{score})"
          end  
        }  
      else  
        puts "Showing #{hits.size <= 10 || show_all ? 'all' : 'top 10'} matches of #{hits.size}:"
        count = hits.size > 10 && show_all ? hits.size : 10
        0.upto(count) { |i| 
          if i < hits.size 
            # Get full fields            
            # If you don't need all of the fields or key, use hits[i].context(30)
            # record_data = fulltext_reader.offset_to_record_data(hits[i].offset) 
            record_data = fulltext_reader.hit_to_record_data(hits[i]) 
            primary_key = fulltext_reader.get_primary_key(record_data) 
            fields = fulltext_reader.get_fields(record_data) 
            p "#{primary_key}: #{fields.join(' ')}"
          end  
        }  
      end  
    else
      puts "No matches found"  
    end
    t4 = Time.new
    puts "----"
    puts "Needed to load cache (#{t2-t1})"
    puts "Needed to find all matches (#{t3-t2})"
    puts "Needed to print matches (#{t4-t3})"
    puts "Total time (#{Time.new - t1})"
  end         
end