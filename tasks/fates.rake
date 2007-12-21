require 'rake/testtask'
require 'rake/rdoctask'

FATE_PATH = File.expand_path(File.dirname(__FILE__) + "/../index/fates")
BASE_PATH = File.expand_path(File.dirname(__FILE__) + "/../index/fates/contacts")

namespace :fates do
  desc "Index the sample contacts for the fates search plugin"
  task :index do
    require 'fileutils'
    require 'fastercsv'
    sample_path = File.expand_path(File.dirname(__FILE__) + "/../spec/samples/contacts.csv")
    
    # Protect against rm -rf /
    puts "Invalid base path" && return if BASE_PATH.empty? || BASE_PATH == '/' || FATE_PATH.empty? || FATE_PATH == '/'
    
    puts "Removing the current index for contacts"
    t1 = Time.new
    FileUtils.rm_rf FATE_PATH 
    
    puts "Preparing fields"
    t2 = Time.new
    field_infos = FTSearch::FieldInfos.new
    field_infos.add_field(:name => :primary_key, :stored => false)
    field_infos.add_field(:name => :first_name) # Default analyzer is the WhitespaceAnalyzer
    field_infos.add_field(:name => :last_name) # Default analyzer is the WhitespaceAnalyzer

    puts "Reading contacts"
    t3 = Time.new
    rows = FasterCSV.read(sample_path)
    
    puts "Indexing contacts"
    t4 = Time.new
    fragment  = FTSearch::FragmentWriter.new(:path => "#{BASE_PATH}-0000000", :field_infos => field_infos)
    rows.each {|row| fragment.add_document(:primary_key => row[0].to_i, :first_name => row[1] || '', :last_name => row[2] || '') }

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

  desc 'Generate documentation for the fates search plugin.'
  Rake::RDocTask.new(:rdoc) do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title    = 'Fates Search Full Text Searching Plugin'
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.rdoc_files.include('README')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
  
  namespace :spec do
    
    $LOAD_PATH << File.join(File.dirname(__FILE__), '..', '..', 'rspec', 'lib') 
    require 'spec'
    require 'spec/rake/spectask'

    module Spec
      class << self; def run; false; end; end
    end          

    desc 'Test the specifications of the fates search plugin.'
    Spec::Rake::SpecTask.new(:spec) do |spec|
      spec.spec_opts = ['--options', 'spec/spec.opts']
      spec.spec_files = FileList['spec/**/*_spec.rb']
    end

    desc 'Document the specifications of the fates search plugin.'
    Spec::Rake::SpecTask.new(:doc) do |spec|
      spec.spec_opts = ['--format', 'specdoc', '--dry-run']
      spec.spec_files = FileList['spec/**/*_spec.rb']
    end

    desc 'Review coverage for the specifications of the fates search plugin.'
    Spec::Rake::SpecTask.new(:rcov) do |spec|
      spec.spec_files = FileList['../spec/**/*_spec.rb']
      spec.rcov = true
      spec.rcov_opts = lambda do
        IO.readlines("spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
      end
    end
  end
end