# See README for Copyright and License information 

require 'rake/testtask'
require 'rake/rdoctask'

FATE_PATH = File.expand_path(File.dirname(__FILE__) + "/../index/fates")
BASE_PATH = File.expand_path(File.dirname(__FILE__) + "/../index/fates/contacts")

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
    rows.each {|row| fragment.add(row[0].to_i, row[1..2]) }

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
          
    # Probablistic sorting is useful for large data sets
    sort = false
    probabilistic_sorting = false 

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
    if hits && hits.size > 0
      if sort
        # Build a weight table for ranking (initialize for nudging certain fields)
        h = Hash.new{|h,k| h[k] = 0}
        weights = Hash.new(1.0)
        weights[0] = 10000000 # :id
        weights[1] = 00000000 # :primary_key
        weights[2] = 20000000 # :first_name
        weights[3] = 10000000 # :last_name
        size = hits.size
        offsets = suffix_array_reader.hits_to_offsets(hits)
        if probabilistic_sorting
          puts "Using probabilistic sorting"      
          iterations = 50 * Math.sqrt(size)
          weight_arr = weights.sort_by{|id,w| id}.map{|_,v| v}
          #sorted = doc_map_reader.rank_offsets_probabilistic(offsets, weight_arr, iterations)
        else
          #sorted = doc_map_reader.rank_offsets(offsets, weights.sort_by{|id,w| id}.map{|_,v| v})
        end
        #sorted.each{|doc_id, score| doc_map_reader.document_id_to_uri(doc_id)}
        #puts "Showing #{sorted.size <= 10 ? 'all' : 'top 10'} matches of #{hits.size}:"
        #ids = sorted[0..10].map{ |doc_id, count| doc_map_reader.document_id_to_uri(doc_id).to_i }
        #contacts = Contact.find(:all, :conditions => ["id in (?)", ids])
        #puts contacts.map{|c| "#{c.first_name} #{c.last_name}"}  
      else  
        puts "Showing #{hits.size <= 10 ? 'all' : 'top 10'} matches of #{hits.size}:"
        0.upto(hits.size) { |i| 
          if i < hits.size 
            record_data = fulltext_reader.offset_to_record_data(hits[i].offset) 
            primary_key = fulltext_reader.get_primary_key(record_data) 
            fields = fulltext_reader.get_fields(record_data) 
            p "#{primary_key}: #{fields.join(',')}"
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
    ## puts "Needed to find, rank, and map ids (#{d3})"
    ## puts "Needed to lookup matches in database (#{Time.new - t4})"
    puts "Total time (#{Time.new - t1})"
  end        

  desc 'Generate documentation for the fate search plugin.'
  Rake::RDocTask.new(:rdoc) do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title    = 'Fate Search Full Text Searching Plugin'
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.rdoc_files.include('README')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end

=begin  
  namespace :spec do
    
    $LOAD_PATH << File.join(File.dirname(__FILE__), '..', '..', 'rspec', 'lib') 
    require 'spec'
    require 'spec/rake/spectask'

    module Spec
      class << self; def run; false; end; end
    end          

    desc 'Test the specifications of the fate search plugin.'
    Spec::Rake::SpecTask.new(:spec) do |spec|
      spec.spec_opts = ['--options', 'spec/spec.opts']
      spec.spec_files = FileList['spec/models/*_spec.rb']
    end

    desc 'Document the specifications of the fate search plugin.'
    Spec::Rake::SpecTask.new(:doc) do |spec|
      spec.spec_opts = ['--format', 'specdoc', '--dry-run']
      spec.spec_files = FileList['spec/**/*_spec.rb']
    end

    desc 'Review coverage for the specifications of the fate search plugin.'
    Spec::Rake::SpecTask.new(:rcov) do |spec|
      spec.spec_files = FileList['../spec/**/*_spec.rb']
      spec.rcov = true
      spec.rcov_opts = lambda do
        IO.readlines("spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
      end
    end
  end
=end  
end