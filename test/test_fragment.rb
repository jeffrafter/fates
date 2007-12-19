# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#

require 'test/unit'
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift "lib"
require 'ftsearch/fragment_writer'

class TestFragment < Test::Unit::TestCase
  include FTSearch
  def setup
    @fragment = FragmentWriter.new(:path => nil)
  end

  def test_add_document
    @fragment.add_document(:body => "Foo bar baz")
    assert_equal(1, @fragment.documents)
    assert_equal(1, @fragment.field_id(:body))
    @fragment.add_document(:body => "Foo bar baz", :baz => "dfdsf sdf")
    assert_equal(1, @fragment.field_id(:body))
    assert_equal(2, @fragment.field_id(:baz))
  end

  def test_fields
    @fragment.add_document(:body => "Foo bar baz")
    assert_equal([:uri, :body], @fragment.fields)
  end
end
