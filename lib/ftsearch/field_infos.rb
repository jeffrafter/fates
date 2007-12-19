# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#
require 'ftsearch/analysis/whitespace_analyzer'

module FTSearch # :nodoc:
  
  # Store field information by adding field definitions using +add_field+. The
  # options for each field will be stored in the internal field hash. Using the
  # options, field information will be analyzed using the specified analyzer. 
  # By default a +WhitespaceAnalyzer+ will be used to find suffixes within the 
  # fields and any results will be stored.
  class FieldInfos
    DEFAULT_OPTIONS = {
      :analyzer => FTSearch::Analysis::WhitespaceAnalyzer.new,
      :stored => true
    }
    
    # Create a new +FieldInfos+ class with a set of default options
    #
    # Valid options:
    # [<tt>:analyzer</tt>] The analyzer instance that will be used to find suffixes within field contents
    # [<tt>:stored</tt>] Boolean indicating whether or not the field will be stored (for example by the suffix reader)
    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      @fields = {}
      @default_options = options
    end

    # Create a new field definition.
    #
    # Required options:
    # [<tt>:name</tt>] The name of the field
    #
    # Valid options:
    # [<tt>:analyzer</tt>] The analyzer instance that will be used to find suffixes within field contents
    # [<tt>:stored</tt>] Boolean indicating whether or not the field will be stored (for example by the suffix reader)
    def add_field(options = {})
      options = @default_options.merge(options)
      raise "You cannot create a field without a name" unless options[:name]
      @fields[options[:name]] = options
    end

    # Lookup the options for a field. If the field specified by +name+ does not 
    # exist, it will be created using the default options.
    def [](name)
      if field_info = @fields[name]
        field_info
      else
        @fields[name] = @default_options
      end
    end
  end
end  # FTSearch