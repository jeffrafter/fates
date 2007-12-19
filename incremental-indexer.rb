
$:.unshift "lib"
$:.unshift  "ext/ftsearch"

require 'ftsearch/fragment_writer'
require 'ftsearch/analysis/simple_identifier_analyzer'
require 'ftsearch/analysis/whitespace_analyzer'

require 'ftsearchrt'

require 'yaml'

BASE_PATH="INDEX_incremental"

field_infos = FTSearch::FieldInfos.new
field_infos.add_field(:name => :uri, :analyzer => FTSearch::Analysis::SimpleIdentifierAnalyzer.new)
field_infos.add_field(:name => :body, :analyzer => FTSearch::Analysis::WhiteSpaceAnalyzer.new)

latest = Dir["#{BASE_PATH}-*"].sort.last

if latest
  fragment  = FTSearch::FragmentWriter.new(:path => latest.succ, :field_infos => field_infos)
  fragment.merge(latest)
else
  fragment  = FTSearch::FragmentWriter.new(:path => "#{BASE_PATH}-0000000", 
                                           :field_infos => field_infos)
end

ARGV.each do |fname|
  fragment.add_document(:uri => fname, :body => File.read(fname))
end

fragment.finish!

require 'fileutils'
FileUtils.rm_r(latest) if latest
