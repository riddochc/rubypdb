# This defines the PalmPDB class, which represents a Palm Database as a whole.

class NoAppinfoClass < Exception
end

class NoSortinfoClass < Exception
end

class PalmPDB
  attr_reader :records, :index
  attr_accessor :header, :appinfo, :sortinfo
  include Enumerable

  def initialize(opts = {})
    @index = []
    @records = {}
    @appinfo = nil
    @sortinfo = nil
    @header = PDB::Header.new()

    if opts[:appinfo_class].nil?
      appinfo_class_name = self.class.name + "::AppInfo"
      begin
        @appinfo_class = Kernel.const_get_from_string(appinfo_class_name)
      rescue NameError
        # Ignore the error, if it happens.
      end
      if @appinfo_class.nil? # or @appinfo_struct_class == PalmPDB::AppInfo
        raise NoAppinfoClass
      end
    else
      @appinfo_class = opts[:appinfo_class]
    end

    if opts[:sortinfo_class].nil?
      sortinfo_class_name = self.class.name + "::SortInfo"
      begin
        @sortinfo_class = Kernel.const_get_from_string(sortinfo_class_name)
      rescue NameError
        # Ignore the error, if it happens.
      end
      if @sortinfo_class.nil? or @sortinfo_class == PalmPDB::SortInfo
        raise NoSortinfoClass
      end
    else
      @sortinfo_class = opts[:sortinfo_class]
    end

    if opts[:data_class].nil?
      @data_class = PDB::Data
      begin
        @data_class = Kernel.const_get_from_string(self.class.name + "::Resource")
      rescue
      end

      begin
        @data_class = Kernel.const_get_from_string(self.class.name + "::Record")
      rescue
      end
    else
      @data_class = opts[:data_class]
    end

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

  # Add a PDB::Data to the PDB
  def <<(datum)
    datum.pdb = self
    # Needs to be added to @index...
    # And to @records...
  end

end
