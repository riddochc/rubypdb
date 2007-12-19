require 'bit-struct'
require 'enumerator'
require 'yaml'

module PDB
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

  def pdb=(p)
    @pdb = p
  end

  def length()
    unless @struct.nil?
      return @struct.length()
    else
      return @data.length
    end
  end

  def category()
    cat = @metadata.attributes.category
    @pdb.appinfo.category(cat)
  end

  def category=(val)
    cat = @pdb.appinfo.category(val) # || @pdb.appinfo.new_category(val)
    attr = PDB::RecordAttributes.new(@metadata.attributes)
    attr.category = cat
    @metadata.attributes = attr
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
