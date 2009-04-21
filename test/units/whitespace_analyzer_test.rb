require File.dirname(__FILE__) + '/../test_helper'

class WhitespaceAnalyzerTest < Test::Unit::TestCase
  context "a whitespace analyzer" do
    setup do
      @analyzer = FateSearch::Analysis::WhitespaceAnalyzer.new
    end

    should "not append suffixes for blank text" do
      assert_equal @analyzer.append_suffixes([], "", 0, 0, 0), []
    end  

    should "append one suffix when there is no whitespace" do
      assert_equal @analyzer.append_suffixes([], "test", 0, 0, 0), [[0, 0, 0]]
    end  
    
    should "append multiple suffixes when there are spaces" do
      assert_equal @analyzer.append_suffixes([], "test1 test2  test3", 0, 0, 0), [[0, 0, 0], [6, 0, 0], [13, 0, 0]]
    end  
    
    should "append multiple suffixes when there are tabs" do
      assert_equal @analyzer.append_suffixes([], "test1\ttest2\t test3", 0, 0, 0), [[0, 0, 0], [6, 0, 0], [13, 0, 0]]
    end  

    should "append multiple suffixes when there are new lines" do
      assert_equal @analyzer.append_suffixes([], "test1\ntest2\n test3", 0, 0, 0), [[0, 0, 0], [6, 0, 0], [13, 0, 0]]
    end  
    
    should "append multiple suffixes when there are carriage returns" do
      assert_equal @analyzer.append_suffixes([], "test1\rtest2\r\ntest3", 0, 0, 0), [[0, 0, 0], [6, 0, 0], [13, 0, 0]]
    end  
    
    should "return suffixes that start at the specified offset" do
      assert_equal @analyzer.append_suffixes([], "test", 10, 0, 0), [[10, 0, 0]]
    end  

  end
end