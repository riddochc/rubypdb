require 'bit-struct'

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

class PDB::Header < BitStruct
  text     :name,       8 * 32
  nest     :attributes, PDB::AttributeFlags
  unsigned :version,    8 * 2
  unsigned :ctime,      8 * 4
  unsigned :mtime,      8 * 4
  unsigned :baktime,    8 * 4
  unsigned :modnum,     8 * 4
  unsigned :appinfo_off,   8 * 4
  unsigned :sortinfo_off,  8 * 4
  text     :type,       8 * 4
  text     :creator,    8 * 4
  unsigned :uniqueid,   8 * 4
end

class PalmPDB
  attr_reader :records, :app_info

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
    # @baktime = Time.at(@baktime)

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
        @appinfo_data = block.read_from_stream(f)

        if (@appinfo_offset > 0)
          @app_info = StdAppInfoBlock.new()
          @app_info.parse(@appinfo_data)
        end

        parse_app_info(@app_info.other)
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

    # puts self.to_yaml
  end

  def parse_app_info(data)
    # Normally, do nothing.  Subclasses override
  end

  def load_resource_index(f)
    @number_of_records.times do |i|
      rie = @resourceclass.new(f)
      @index << rie
    end
  end

  def load_record_index(f)
    lastoffset = 0
    @number_of_records.times do |i|
      rie = @recordclass.new(f)
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
      record.load(self)
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

