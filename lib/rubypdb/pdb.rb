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
    @next_r_id = 1

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
    # @header.resource_index.next_index = 0 # TODO: How is this determined?

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

  # Add a (possibly subclassed) PDB::Data to the PDB
  def <<(data)
    # If it already has an r_id assigned, don't bother assigning it one.
    unless data.metadata.r_id != 0 
      metadata = data.metadata
      metadata.r_id = @next_r_id
      data.metadata = metadata
      @next_r_id += 1
    end

    self[data.metadata.r_id] = data
  end

  def []=(r_id, data)
    # Make sure the data's metadata record is consistent with the r_id assigned to it.
    if data.metadata.r_id != r_id
      metadata = data.metadata
      metadata.r_id = r_id
      data.metadata = metadata
    end

    # If we're not overwriting an existing record, the number of records increases.
    # If not, the index entry needs replacing.
    if @records[r_id].nil?
      res_index = @header.resource_index
      res_index.number_of_records += 1
      @header.resource_index = res_index
    else
      @index = @index.delete_if {|i| i.r_id == r_id }
    end

    @index << data.metadata
    @records[r_id] = data
  end

  def records=(data)
    @index = []
    @records = {}
    @next_r_id = 1
    if data.is_a? Array  # There's no r_ids already assigned.
      data.each do |rec|
        metadata = rec.metadata
        metadata.r_id = @next_r_id
        rec.metadata = metadata
        self[rec.metadata.r_id] = rec
        @next_r_id += 1
      end
    elsif data.is_a? Hash
      data.each_pair do |r_id, rec|
        self[r_id] = data
      end
    end
  end

  # Either delete the data with the r_id of a number, or the provide the object to delete.
  def delete(thing)
    if thing.is_a? Integer
      @index = @index.delete_if {|idx|  idx.r_id == thing }
      @records = @records.delete_if {|idx, data|  idx == thing }
    else
      if thing.respond_to?(:r_id)
        r_id = thing.r_id
        @index = @index.delete_if {|idx| idx.r_id == r_id }
        @records = @records.delete_if {|idx, data|  data == thing}
      end
    end
    res_index = @header.resource_index
    res_index.number_of_records = @index.length
    @header.resource_index = res_index
  end
end
