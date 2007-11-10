require 'bit-struct'
require 'enumerator'

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
  unsigned :id,     8 * 2
  unsigned :offset, 8 * 4
end

class PDB::RecordAttributes < BitStruct
  unsigned :delete, 1  # 0x080
  unsigned :dirty,  1  # 0x040
  unsigned :busy,   1  # 0x020
  unsigned :secret, 1  # 0x010
  unsigned :attr4,  1  # 0x008
  unsigned :attr3,  1  # 0x004
  unsigned :attr2,  1  # 0x002
  unsigned :attr1,  1  # 0x001
end

class PDB::Record < BitStruct
  unsigned :offset, 8 * 4
  nest     :attributes,  PDB::RecordAttributes
  unsigned :id,     8 * 3
end


class PDB::StandardAppInfoBlock < BitStruct
  unsigned  :renamed_categories,  8 * 2
  16.times do |i|
    text      "category_#{i}".to_sym,  8 * 16
  end
  16.times do |i|
    unsigned  "category_#{i}_id".to_sym, 8 * 1
  end
  unsigned :last_unique_id, 8 * 1
  rest     :rest
end


class PalmPDB
  attr_reader :records, :index
  attr_accessor :header, :appinfo, :sortinfo

  def initialize()
    @index = []
    @records = {}
    @appinfo = nil
    @sortinfo = nil
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
      if @header.attributes.resource == true
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
      @appinfo = PDB::StandardAppInfoBlock.new(@appinfo_data)
    end

    if sortinfo_length > 0
      f.pos = @header.sortinfo_offset
      @sortinfo_data = f.read(sortinfo_length)
      @sortinfo = nil  # This really is app-specific, isn't it?
    end

    i = 0
    @index.each_cons(2) do |curr, nxt|
      length = nxt.offset - curr.offset  # Find the length to the next record
      f.pos = curr.offset
      data = f.read(length)
      @records[curr.id] = data
      i = i + 1 
    end
    # ... And then the last one.
    entry = @index.last
    f.pos = entry.offset
    data = f.read()  # Read to the end
    @records[entry.id] = data
  end

  def each(&block)
    @index.each {|i|
      yield i, @records[i.id]
    }
  end


  $EPOCH_1904 = 2082844800
  def ctime()
    Time.at(@header.ctime - $EPOCH_1904)
  end

  def mtime()
    Time.at(@header.mtime - $EPOCH_1904)
  end

  def backup_time()
    Time.at(@header.baktime - $EPOCH_1904)
  end
end