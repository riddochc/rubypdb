# This is a high-level interface to PDB::Resource / PDB::Record
# PDB::RecordAttributes, and the data of the record/resource

module PDB
end

class PDB::Data
  def initialize(pdb, opts = {})
    @pdb = pdb

    if opts[:metadata_class].nil?
      if self.class.name =~ /Record$/
        @metadata_class = PDB::Record
      elsif self.class.name =~ /Resource$/
        @metadata_class = PDB::Resource
      end
    else
      @metadata_class = opts[:metadata_class]
    end
    
    @metadata = @metadata_class.new()
    
    # If there isn't a data_struct_class, don't make a @struct thing for it.
    @struct_class = opts[:data_struct_class] || (self.class.name + "::Struct").get_full_const
    
    unless @struct_class.nil? or @struct_class == Struct
      @struct = @struct_class.new()
    end
  end

  def metadata=(stuff)
    @metadata = @metadata_class.new(stuff)
  end
  
  def metadata()
    @metadata
  end
  
  def struct=()
    unless @struct_class.nil?
      @struct = @struct_class.new()
    end
  end
  
  def struct()
    @struct
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
    if @pdb.appinfo.standard_appinfo == true and @metadata_class == PDB::Record
      c = @metadata.attributes.category
      @pdb.appinfo.category_offset(c)
    end
  end

  def category=(val)
    if @pdb.appinfo.standard_appinfo == true and @metadata_class == PDB::Record
      unless val.is_a? PDB::AppInfo::Category
        raise "Value should be an instance of PDB::AppInfo::Category"
      end
      offset = @pdb.appinfo.category_offset(val)
      # if cat.nil?
      attr = PDB::RecordAttributes.new(@metadata.attributes)
      attr.category = offset
      @metadata.attributes = attr
    end
  end
end
