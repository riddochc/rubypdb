# This is code related to loading databases, records, resources, etc.

require 'enumerator'

module PDB
end

class PDB::AppInfo
  def load(data)
    if @standard_appinfo == true
      # Using standard app info block
      @data = PDB::StandardAppInfoBlock.new(data)

      @categories = []
      16.times do |i|
        name = @data.send("category_name[#{i}]")
        id = @data.send("category_id[#{i}]")
        renamed = (@data.renamed_categories[i] == 1) # Is the ith bit 1?
        if name != ""
          c = PDB::AppInfo::Category.new(self, :name => name, :id => id, :renamed => renamed)
          @categories << c
        end
      end

      unless @struct_class.nil? or @struct_class == Struct
        @struct = @struct_class.new(@data.rest)
      end
    else
      # Not using standard app info block.
      # In this case, this function should be overwritten by subclass.
      @data = data
    end
  end
end

class PDB::Data
  def load(data)
    format_class = (self.class.name + "::Struct").get_full_const

    unless format_class.nil? or format_class == Struct
      @struct = format_class.new(data)
    end

    @data = data
  end
end

class PalmPDB

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

      unless @appinfo_class.nil?
        @appinfo = @appinfo_class.new(self)
        @appinfo.load(@appinfo_data)
      else
        @appinfo = nil
      end
    end

    if sortinfo_length > 0
      f.pos = @header.sortinfo_offset
      @sortinfo_data = f.read(sortinfo_length)

      unless @sortinfo_class.nil?
        @sortinfo = @sortinfo_class.new(self)
        @sortinfo.load(@sortinfo_data)
      else
        @sortinfo = nil
      end
    end
    
    r_opts = {}
    unless @data_struct_class.nil?
      r_opts[:data_struct_class] = @data_struct_class
    end
    
    i = 0
    @index.each_cons(2) do |curr, nxt|
      length = nxt.offset - curr.offset  # Find the length to the next record
      f.pos = curr.offset
      data = f.read(length)
      
      rec = @data_class.new(self, r_opts)
      rec.metadata = curr
      rec.load(data)
      
      @records[curr.r_id] = rec # @data_class.new(self, :metadata => curr, :binary_data => data)
      i = i + 1 
    end
    # ... And then the last one.
    entry = @index.last
    f.pos = entry.offset
    data = f.read()  # Read to the end
    
    rec = @data_class.new(self, r_opts)
    rec.metadata = entry
    rec.load(data)
    @records[entry.r_id] = rec # @data_class.new(self, :metadata => entry, :binary_data => data)
    
    @next_r_id = @index.collect {|i| i.r_id }.max + 1
  end

end