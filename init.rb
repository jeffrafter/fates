$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "lib"))
require 'fragment_writer'
require 'suffix_array_reader'
require 'fulltext_reader'
require 'analysis/analyzer'
require 'analysis/simple_identifier_analyzer'
require 'analysis/whitespace_analyzer'
require 'fates'