#!/usr/bin/env ruby
#
# copyright 2005, Chris Riddoch
# loading and unloading code shamelessly borrowed from Palm::PDB.  sort of...

require "yaml"

$header_length = 72
$record_index_header_length = 6

$EPOCH_1904 = 2082844800

class RecordEntry
  @@attribute_flags = {
    "Delete" => 0x80,
    "Dirty" => 0x40,
    "Busy" => 0x20,
    "Secret" => 0x10,
  }
  @@record_index_length = 8

  attr_accessor :offset, :attribute, :id, :length, :buffer

  def initialize(f)
    buffer = f.read(@@record_index_length)
    @offset, attrib, id = buffer.unpack("N C C3")

    # Define the attributes
    @attribute = {}
    @@attribute_flags.each_pair { |flag, mask|
      if ((attrib & mask) != 0)
        @attribute[flag] = true
      else
        @attribute[flag] = false
      end
    }
  end

  def load
  end
end

class ResourceEntry
  @@resource_index_length = 10
  attr_accessor :offset, :type, :id

  def initialize(f)
    buffer = f.read(@@resource_index_length)
    @type, @id, @offset = buffer.unpack("a4 n N")
  end
end

class PDB_block
  attr_accessor :name, :position, :length

  def initialize(name, position)
    @name = name
    @position = position
  end

  def <=>(other)
    self.position <=> other.position
  end

  def read_from_stream(stream)
    stream.pos = @position
    stream.read(@length)
  end
end

class PalmPDB
  @@attribute_flags = {
    "resource" => 0x0001,
    "read-only" => 0x0002,
    "AppInfo dirty" => 0x0004,
    "backup" => 0x0008,
    "OK newer" => 0x0010,
    "reset" => 0x0020,
    "open" => 0x8000,
    "launchable" => 0x0200,
    "ResDB" => 0x0001,
    "ReadOnly" => 0x0002,
    "AppInfoDirty" => 0x0004,
    "Backup" => 0x0008,
    "OKToInstallNewer" => 0x0010,
    "ResetAfterInstall" => 0x0020,
    "CopyPrevention" => 0x0040,
    "Stream" => 0x0080,
    "Hidden" => 0x0100,
    "LaunchableData" => 0x0200,
    "Recyclable" => 0x0400,
    "Bundle" => 0x0800,
    "Open" => 0x8000,
  }

  def initialize ()
    @index = []
  end

  def open_PDB_file(fname)
    File.open(fname, "rb") do |f|
      load_PDB(f)
    end
  end

  def load_PDB(f)
    f.seek(0, IO::SEEK_END)
    @eof_pos = f.pos
    f.pos = 0  # return to beginning of file

    header = f.read($header_length) # read the header

    fields = header.unpack("A32 n n N N N N N N a4 a4 N")
    @name, @attrib, @version, @ctime, @mtime, @baktime,
      @modnum, @appinfo_offset, @sort_offset, @type, @creator,
      @uniqueIDseed = fields
 
    @ctime = Time.at(@ctime - $EPOCH_1904)
    @mtime = Time.at(@mtime - $EPOCH_1904)
    @baktime = Time.at(@baktime)

    @attribute = Hash.new()
    @@attribute_flags.each_pair { |flag, mask|
      if ((@attrib & mask) != 0)
        @attribute[flag] = true
      else
        @attribute[flag] = false
      end
    }
      
    resource_index = f.read($record_index_header_length)

    @next_index, @number_of_records = resource_index.unpack("N n")
    if ((@attribute["resource"] == true) or (@attribute["ResDB"] == true))
      load_resource_index(f)
    else
      load_record_index(f)
    end

    first_record_offset = @index[0].offset
    positions = []

    if (@appinfo_offset != 0)
      positions << PDB_block.new(:appinfo, @appinfo_offset)
    end
    
    if (@sort_offset != 0)
      positions << PDB_block.new(:sortinfo, @sort_offset)
    end

    if (first_record_offset != 0)
      positions << PDB_block.new(:first_record, first_record_offset)
    end

    positions << PDB_block.new(:eof, @eof_pos)

    # Validating relative positions of blocks in the file
    if positions != positions.sort
      puts "Invalid PDB format"
    end

    positions.each_with_index do |block, index |
      following = positions[index + 1]
      unless following.nil?
        block.length = following.position - block.position
      end
    end

    positions.each do | block |
      case block.name
      when :appinfo
         @appinfo = block.read_from_stream(f)
      when :sortinfo
        @sortinfo = block.read_from_stream(f)
      when :first_record
        f.pos = block.position
        compute_record_sizes
        load_items(f)
      end
    end

    if ((@attribute["resource"] == true) or (@attribute["ResDB"] == true))
      @resources = @index 
    else
      @records = @index
    end
    @index = nil


    puts self.to_yaml
  end

  def load_resource_index(f)
    @number_of_records.times do |i|
      rie = ResourceEntry.new(f)
      @index << rie
    end
  end

  def load_record_index(f)
    lastoffset = 0
    @number_of_records.times do |i|
      rie = RecordEntry.new(f)
      if rie.offset == lastoffset
        puts "Record #{i} has same offset as previous one: #{rie.offset}"
      end
      lastoffset = rie.offset
      @index << rie
    end
  end

  def load_items(f)
    @index.each do | record |
      if (f.pos != record.offset)
        f.pos = record.offset
      end
      record.buffer = f.read(record.length)
      record.load
    end
  end

  def compute_record_sizes()
    @index.each_with_index do | entry, i |
      following = @index[i + 1]
      if following.nil?
        entry.length = @eof_pos - entry.offset
      else
        entry.length = following.offset - entry.offset
      end
    end
  end
end

a = PalmPDB.new()
a.open_PDB_file("fuelLogDB.pdb")

