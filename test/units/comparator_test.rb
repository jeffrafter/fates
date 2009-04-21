require File.dirname(__FILE__) + '/../test_helper'

class ComparatorTest < Test::Unit::TestCase
  context "a comparator" do
    setup do
      @comparator = FateSearch::Comparison::Comparator.new
    end

    should "downcase the prepared term" do
      assert_equal "muppet", @comparator.prepare("Muppet")
    end
    
    should "decode the prepared term" do
      assert_equal "\320\233\321\216\320\261\320\276\320\262\320\275\320\260\321\217 \320\270\321\201\321\202\320\276\321\200\320\270\321\217", @comparator.prepare("Любовная история")
    end

  end
end