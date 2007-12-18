#!/usr/bin/env ruby


require File.join(File.dirname(__FILE__), '..', 'rubypdb', 'common')
require File.join(File.dirname(__FILE__), '..', 'rubypdb', 'pdb')
require 'iconv'

class PDB::MemoDB < PalmPDB
end

class PDB::MemoDB::AppInfo < PDB::AppInfo
  def initialize(*rest)
    super(true, *rest)  # Uses standard categories.
  end
end

class PDB::MemoDB::Record < PDB::Data
  def title()
    @struct.title
  end

  def content()
    @struct.content
  end

  def to_yaml(opts = {})
    YAML::quick_emit( self.object_id, opts ) do |out|
      out.map( to_yaml_style ) do |map|
        map.add('Title', title())
        map.add('Content', content())
        map.add('Metadata', metadata_struct())
      end
    end
  end
end

class PDB::MemoDB::Record::Struct
  attr_accessor :title, :content

  def initialize(data)
    load(data)
  end

  def load(data)
    data.strip!
    @data = Iconv.conv("UTF-8", "Windows-1252", @data)
    if data =~ /([^\n]*)\n+(.+)/m
      @title = $1
      @content = $2
    else
      @title = @content = data
    end
  end

  def dump()
    @title + "\n" + @content
  end
end
