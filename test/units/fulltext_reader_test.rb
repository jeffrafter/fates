require File.dirname(__FILE__) + '/../test_helper'

class FulltextReaderTest < Test::Unit::TestCase
  context "a fulltext reader" do
    setup do
      @io = StringIO.new
      @fulltext = FateSearch::FulltextReader.new(:io => @io)
    end

    should "allow you to create against a memory stream" do
      assert_not_nil @fulltext
    end
    
    should "allow you to create against a path"
    should "get data from the stream"
    should "convert an offset to record data"
    should "convert a hit to record data"
    should "get a primary key from the header data"
    should "get fields"
    should "rank offsets"
    should "dump data in blocks for use in the writer"
    should "convert an offset to the start of a record"
    
  end
end