# This is a high-level interface to PDB::Resource / PDB::Record
# PDB::RecordAttributes, and the data of the record/resource

module PDB
end

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
