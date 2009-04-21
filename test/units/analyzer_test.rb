require File.dirname(__FILE__) + '/../test_helper'

class AnalyzerTest < Test::Unit::TestCase
  context "an abstract analyzer" do
    setup do
      @analyzer = FateSearch::Analysis::Analyzer.new
    end

    should "not append any suffixes by default" do
      assert_nil @analyzer.append_suffixes([], "this is a sample bit of text", 0, 0, 0)
    end
  end
end