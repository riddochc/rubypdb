# This is a high-level interface to PDB::Resource / PDB::Record
# PDB::RecordAttributes, and the data of the record/resource

module PDB
end

class PDB::Data
  attr_accessor :struct, :metadata

  def initialize(pdb, opts = {})
    @pdb = pdb

    unless opts[:metadata].nil?
      @metadata = opts[:metadata]
    else
      if opts[:metadata_class].nil?
        if self.class.name =~ /Record$/
          @metadata = PDB::Record.new()
        elsif self.class.name =~ /Resource$/
          @metadata = PDB::Resource.new()
        end
      else
        @metadata = opts[:metadata_class].new()
      end
    end
    
    if opts[:data_struct_class].nil?
      begin
        struct_class = Kernel.const_get_from_string(self.class.name + "::Struct")
      rescue
      end
    else
      struct_class = opts[:data_struct_class]
    end

    unless opts[:binary_data].nil?
      load(opts[:binary_data])
    else
      unless struct_class.nil?
        @struct = struct_class.new()
      end
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
