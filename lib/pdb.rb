require 'bit-struct'
require 'enumerator'
require 'yaml'

libdir = File.split(__FILE__).first
require libdir + '/common.rb'

module PDB
end

class PDB::AttributeFlags < BitStruct
  unsigned :open,       1   #0x8000
  unsigned :unk_3,      1   #0x4000
  unsigned :unk_2,      1   #0x2000
  unsigned :unk_1,      1   #0x1000
  unsigned :bundle,     1   #0x0800
  unsigned :recyclable, 1   #0x0400
  unsigned :launchable, 1   #0x0200
  unsigned :hidden,     1   #0x0100
  unsigned :stream,     1   #0x0080
  unsigned :copy_prev,  1   #0x0040
  unsigned :reset,      1   #0x0020
  unsigned :newer_ok,   1   #0x0010
  unsigned :backup,     1   #0x0008
  unsigned :dirty,      1   #0x0004
  unsigned :read_only,  1   #0x0002
  unsigned :resource,   1   #0x0001
end

class PDB::ResourceIndex < BitStruct
  unsigned :next_index, 8 * 4
  unsigned :number_of_records,    8 * 2
end

class PDB::Header < BitStruct
  text     :name,       8 * 32
  nest     :attributes, PDB::AttributeFlags
  unsigned :version,    8 * 2
  unsigned :ctime,      8 * 4
  unsigned :mtime,      8 * 4
  unsigned :baktime,    8 * 4
  unsigned :modnum,     8 * 4
  unsigned :appinfo_offset,   8 * 4
  unsigned :sortinfo_offset,  8 * 4
  text     :type,       8 * 4
  text     :creator,    8 * 4
  unsigned :uniqueid,   8 * 4
  nest     :resource_index, PDB::ResourceIndex
end

class PDB::Resource < BitStruct
  text     :type,   8 * 4
  unsigned :r_id,     8 * 2
  unsigned :offset, 8 * 4
end

class PDB::RecordAttributes < BitStruct
  unsigned :delete, 1  # 0x080
  unsigned :dirty,  1  # 0x040
  unsigned :busy,   1  # 0x020
  unsigned :secret, 1  # 0x010
  unsigned :category,  4  # 0x008 - 0x001
end

class PDB::Record < BitStruct
  unsigned :offset, 8 * 4
  nest     :attributes,  PDB::RecordAttributes
  unsigned :r_id,     8 * 3
end

class PDB::StandardAppInfoBlock < BitStruct
  unsigned  :renamed_categories,  8 * 2
  16.times do |i|
    text      "category_name[#{i}]".to_sym,  8 * 16
  end
  16.times do |i|
    unsigned  "category_id[#{i}]".to_sym, 8 * 1
  end
  unsigned :last_unique_id, 8 * 1
  rest     :rest
end

# Higher-level interface to PDB::StandardAppInfoBlock
class PDB::AppInfo
  attr_accessor :struct, :standard_appinfo, :data
  attr_reader :categories

  def initialize(standard_appinfo, pdb, *rest)
    @standard_appinfo = standard_appinfo
    @pdb = pdb
    data = rest.first

    unless data.nil?
      load(data)
    end
  end

  def load(data)
    if @standard_appinfo == true
      # Using standard app info block
      @data = PDB::StandardAppInfoBlock.new(data)

      # Define better structures for categories.
      # It's a list, of length 16.
      # At each position, there's a one-element hash. of name and id.
      @categories = []
      16.times do |i|
        @categories[i] = { 'name' => @data.send("category_name[#{i}]"),
                           'id' => @data.send("category_id[#{i}]") }
      end

      appinfo_struct_class_name = self.class.name + "::Struct"
      begin
       appinfo_struct_class = Kernel.const_get_from_string(appinfo_struct_class_name)
      rescue NameError
        #puts appinfo_struct_class_name + " does not exist."
      end

      unless appinfo_struct_class.nil?
        @struct = appinfo_struct_class.new(@data.rest)
      end
    else
      # Not using standard app info block.
      # In this case, this function should be overwritten by subclass.
      @data = data
    end
  end

  def dump()
    unless @struct.nil?
      if @standard_appinfo == true
        @data.rest = @struct.to_s
      end
      return @data.to_s
    else
      return @data
    end
  end

  def length()
    unless @struct.nil?
      if @standard_appinfo == true
         @data.rest = @struct.to_s
      end
      return @data.length
    else
      return @data.length
    end
  end

  
  yaml_as "tag:syntacticsugar.org,2007:palm_appinfo"

  def to_yaml(opts = {})
    YAML::quick_emit( self.object_id, opts ) do |out|
      out.map( to_yaml_style ) do |map|
        map.add('Standard_appinfo', self.standard_appinfo)
        if self.standard_appinfo == true
          map.add('Categories', self.categories)
          map.add('Renamed_categories', self.data.renamed_categories)
          map.add('Last_unique_id', self.data.last_unique_id)
        end
        map.add('Custom_data', self.struct)
      end
    end
  end

end

# This is a high-level interface to PDB::Resource / PDB::Record
# PDB::RecordAttributes, and the data of the record/resource
class PDB::Data
  attr_accessor :struct, :metadata

  def initialize(pdb, metadata, *rest)
    @pdb = pdb
    @metadata = metadata
    record = rest.first

    unless record.nil?
      load(record)
    end
  end

  def load(data)
    format_class_name = self.class.name + "::Struct"
    begin
      format_class = Kernel.const_get_from_string(format_class_name)
    rescue NameError
      # puts format_class_name + " does not exist."
    end

    # puts "Format class: #{format_class}"
    unless format_class.nil?
      @struct = format_class.new(data)
    end

    @data = data
  end


  def dump()
    unless @struct.nil?
      return @struct.to_s
    else
      return @data
    end
  end

  def length()
    unless @struct.nil?
      return @struct.length()
    else
      return @data.length
    end
  end

  def metadata_struct()
    { # 'metadata' => self.metadata,
     'internal_id' => self.metadata.r_id,
     'delete' => (self.metadata.attributes.delete == '1' ? true : false),
     'dirty' => (self.metadata.attributes.dirty == '1' ? true : false),
     'busy' => (self.metadata.attributes.busy == '1' ? true : false),
     'secret' => (self.metadata.attributes.secret == '1' ? true : false),
     'category' => self.metadata.attributes.category,
    }
  end

end

class PalmPDB
  attr_reader :records, :index
  attr_accessor :header, :appinfo, :sortinfo
  include Enumerable

  def initialize()
    @index = []
    @records = {}
    @appinfo = nil
    @sortinfo = nil
    @header = PDB::Header.new()
  end

  def load(f)
    f.seek(0, IO::SEEK_END)
    @eof_pos = f.pos
    f.pos = 0  # return to beginning of file

    header_size = PDB::Header.round_byte_length  # 78
    header_data = f.read(header_size)
    @header = PDB::Header.new(header_data)   # Read the header.

    # Next comes metadata for resources or records...
    resource_size = PDB::Resource.round_byte_length
    record_size = PDB::Record.round_byte_length

    @header.resource_index.number_of_records.times do |i|
      if @header.attributes.resource == 1
        @index << PDB::Resource.new(f.read(resource_size))
      else
        @index << PDB::Record.new(f.read(record_size))
      end
    end

    # Now, a sanity check...
    # Each entry in the index should have a unique offset.
    # Which means, the number of unique offsets == number of things in the index
    unless @index.collect {|i| i.offset }.uniq.length == @index.length
      puts "Eeek.  Multiple records share an offset!"
    end
    # And just to be sure they're in a sensible order...
    @index = @index.sort_by {|i| i.offset }

    # The order of things following the headers:
    #   1- Appinfo, Sortinfo, Records
    #   2 - Appinfo, Records
    #   3 - Sortinfo, Records
    #   4 - Records
    #
    # Unfortunately, it's not necessarily clear what the length of any of these
    # are ahead of time, so it needs to be calculated.

    appinfo_length = 0
    sortinfo_length = 0
    if @header.appinfo_offset > 0
      if @header.sortinfo_offset > 0
        appinfo_length = @header.sortinfo_offset - @header.appinfo_offset  # 1
        sortinfo_length = @index.first.offset - @header.sortinfo_offset
      else
        appinfo_length = @index.first.offset - @header.appinfo_offset      # 2
      end
    elsif @header.sortinfo_offset > 0
      sortinfo_length = @index.first.offset - @header.sortinfo_offset      # 3
    end

    if appinfo_length > 0
      f.pos = @header.appinfo_offset
      @appinfo_data = f.read(appinfo_length)
      appinfo_class_name = self.class.name + "::AppInfo"
      
      begin
        appinfo_class = Kernel.const_get_from_string(appinfo_class_name)
      rescue NameError
        puts appinfo_class_name + " does not exist."
      end

      unless appinfo_class.nil?
        @appinfo = appinfo_class.new(self, @appinfo_data)
      else
        @appinfo = nil
      end
    end

    if sortinfo_length > 0
      f.pos = @header.sortinfo_offset
      @sortinfo_data = f.read(sortinfo_length)

      sortinfo_class_name = self.class.name + "::SortInfo"
      
      begin
        sortinfo_class = Kernel.const_get_from_string(sortinfo_class_name)
      rescue NameError
        puts sortinfo_class_name + " does not exist."
      end

      unless sortinfo_class.nil?
        @sortinfo = sortinfo_class.new(@sortinfo_data)
      else
        @sortinfo = nil
      end
    end

    if @header.attributes.resource == 1  # Is it a resource, or a record?
      data_class_name = self.class.name + "::Resource"
    else
      data_class_name = self.class.name + "::Record"
    end

    data_class = PDB::Data
    begin
      data_class = Kernel.const_get_from_string(data_class_name)
    rescue
    end

    i = 0
    @index.each_cons(2) do |curr, nxt|
      length = nxt.offset - curr.offset  # Find the length to the next record
      f.pos = curr.offset
      data = f.read(length)
      @records[curr.r_id] = data_class.new(self, curr, data)
      i = i + 1 
    end
    # ... And then the last one.
    entry = @index.last
    f.pos = entry.offset
    data = f.read()  # Read to the end
    @records[entry.r_id] = data_class.new(self, entry, data)
  end

  def each(&block)
    @records.each_pair {|k, record|
      yield(record)
    }
  end

  def ctime()
    Time.from_palm(@header.ctime)
  end

  def ctime=(t)
    @header.ctime = t.to_palm
  end

  def mtime()
    Time.from_palm(@header.mtime)
  end

  def mtime=(t)
    @header.mtime = t.to_palm
  end

  def backup_time()
    Time.from_palm(@header.baktime)
  end

  def backup_time=(t)
    @header.baktime = t.to_palm
  end
  
  # This should be done before dumping or doing a deeper serialization.
  def recompute_offsets()
    @header.resource_index.number_of_records = @records.length
    @header.resource_index.next_index = 0 # TODO: How is this determined?

    curr_offset = PDB::Header.round_byte_length

    # Compute length of index...
    unless @index == []
      @index.each do |i|
        curr_offset += i.length()
      end
    end

    unless @appinfo.nil?
      @header.appinfo_offset = curr_offset
      curr_offset += @appinfo.length()
    end

    unless @sortinfo.nil?
      @header.sortinfo_offset = curr_offset
      curr_offset += @sortinfo.length()
    end

    ## And here's the mysterious two-byte filler.
    #curr_offset += 2

    unless @index.length == 0
      @index.each do |i|
        rec = @records[i.r_id]
        i.offset = curr_offset
        curr_offset += rec.length
      end
    end
  end

  def dump(f)
    recompute_offsets()
    f.write(@header)

    @index.each do |i|
      f.write(i)
    end

    unless @appinfo.nil?
      f.write(@appinfo.dump())
    end

    unless @sortinfo.nil?
      f.write(@sortinfo.dump())
    end

    @index.each do |i|
      record = @records[i.r_id]
      f.write(record.dump())
    end
  end

  yaml_as "tag:syntacticsugar.org,2007:palm_db"

  def to_yaml(opts = {})
    YAML::quick_emit( self.object_id, opts ) do |out|
        out.map( to_yaml_style ) do |map|
          map.add('Name', self.header.name)
          map.add('Type', self.header.type)
          map.add('Creator', self.header.creator)
          map.add('Version', self.header.version)
          map.add('Creation_time', self.ctime)
          map.add('Modification_time', self.mtime)
          map.add('Backup_time', self.backup_time)
          map.add('Mod_number', self.header.modnum)
          map.add('Unique_ID', self.header.uniqueid)
          map.add('Next_index', self.header.resource_index.next_index)
          map.add('Flags', self.header.attributes)
          map.add('AppInfo', self.appinfo) unless self.appinfo == nil
          map.add('SortInfo', self.sortinfo) unless self.sortinfo == nil
          map.add('Records', self.records.values)
        end
      end
  end
end
