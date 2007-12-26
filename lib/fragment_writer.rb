# See README for Copyright and License information 

require 'fileutils'
require 'suffix_array_writer'
require 'suffix_array_reader'
require 'fulltext_writer'
require 'fulltext_reader'

module FateSearch
  class FragmentWriter
    DEFAULT_OPTIONS = {
    }

    attr_reader :fulltext_writer, :suffix_array_writer, :empty

    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      @empty = true
      @path = options[:path]
      if @path
        @path   = File.expand_path(@path)
        @tmpdir = @path + "#{Process.pid}-#{rand(100000)}"
        FileUtils.mkdir_p(@tmpdir)
        @fulltext_path = File.join(@tmpdir, "fulltext")
        @suffix_array_path = File.join(@tmpdir, "suffixes")
      end
      @fulltext_writer = options[:fulltext_writer] || FulltextWriter.new(:path => @fulltext_path)
      @suffix_array_writer = options[:suffix_array_writer] || SuffixArrayWriter.new(:path => @suffix_array_path)
      @analyzers = options[:analyzers]
    end

    def add(primary_key, fields)
      @empty = false
      @fulltext_writer.add(primary_key, fields, @analyzers, @suffix_array_writer)      
    end

    def merge(fragment_directory)
      raise "Cannot import old data unless the destination Fragment is empty." unless @empty
      fulltext_reader = FulltextReader.new(:path => "#{fragment_directory}/fulltext")
      suffix_array_reader = SuffixArrayReader.new(fulltext_reader, nil, :path => "#{fragment_directory}/suffixes")
      @fulltext_writer.merge(fulltext_reader)
      @suffix_array_writer.merge(suffix_array_reader)
    end

    def finish!
      @fulltext_writer.finish!
      fulltext = @fulltext_writer.data
      @suffix_array_writer.finish!(fulltext)
      if @path
        File.rename(@tmpdir, @path)
      end
    end
  end
end