require File.dirname(__FILE__) + '/../test_helper'

class SimpleIdentifierAnalyzerTest < Test::Unit::TestCase
  context "a simple identifier analyzer" do
    setup do
      @analyzer = FateSearch::Analysis::SimpleIdentifierAnalyzer.new
    end

    should "not append suffixes for blank text" do
      assert_equal @analyzer.append_suffixes([], "", 0, 0, 0), []
    end  

    should "append one suffix when there is one identifier" do
      assert_equal @analyzer.append_suffixes([], "test", 0, 0, 0), [[0, 0, 0]]
      assert_equal @analyzer.append_suffixes([], "Test", 0, 0, 0), [[0, 0, 0]]
      assert_equal @analyzer.append_suffixes([], "Test39", 0, 0, 0), [[0, 0, 0]]
      assert_equal @analyzer.append_suffixes([], "Test_39", 0, 0, 0), [[0, 0, 0]]
      assert_equal @analyzer.append_suffixes([], "_test", 0, 0, 0), [[0, 0, 0]]
    end  
    
    should "append multiple suffixes when there are breaking characters" do
      assert_equal @analyzer.append_suffixes([], "test1 test2", 0, 0, 0), [[0, 0, 0], [6, 0, 0]]
      assert_equal @analyzer.append_suffixes([], "test1?test2", 0, 0, 0), [[0, 0, 0], [6, 0, 0]]
    end  
    
    should "not append suffixes for invalid identifiers" do
      assert_equal @analyzer.append_suffixes([], "1", 0, 0, 0), []
      assert_equal @analyzer.append_suffixes([], "$@!", 0, 0, 0), []
    end  

    should "return suffixes that start at the specified offset" do
      assert_equal @analyzer.append_suffixes([], "test", 10, 0, 0), [[10, 0, 0]]
    end  
  end
end