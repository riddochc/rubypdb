# This is code for manipulating AppInfo structures at a higher-level.

module PDB
end

class PDB::AppInfo::Category
  attr_reader :name
  attr_accessor :id, :renamed
  
  def initialize(appinfo, opts = {})
    @appinfo = appinfo
    @name = opts[:name] || ""
    @id = opts[:id] || 0
    @renamed = opts[:renamed] || false
  end
  
  # Renaming a category.
  def name=(str)
    if str.length > 16
      raise "Category name too long (should be <= 16 bytes)"
    else
      @name = str
      @renamed = true
    end
  end
end

# Higher-level interface to PDB::StandardAppInfoBlock
class PDB::AppInfo
  attr_accessor :struct, :standard_appinfo, :data
  attr_reader :categories

  def initialize(pdb, opts = {})
    @pdb = pdb

    if opts[:standard_appinfo] == true
      @standard_appinfo = true
    end
    
    if @standard_appinfo == true
      @categories = []
    end

    @struct_class = opts[:struct_class] || (self.class.name + "::Struct").get_full_const

    unless @struct_class.nil? or @struct_class == Struct
     @struct = @struct_class.new()
    end
  end

  # Dual-lookup: Look up a category by either id or name.
  def category(val)
    if val.is_a? Integer
      @categories.find {|c| c.id == val }
    else
      @categories.find {|c| c.name == val.to_s }
    end
  end
  
  # Look up the category object by offset, or the offset by the category object
  def category_offset(i)
    if i.is_a? Integer
      @categories[i]
    else
      @categories.index(i)
    end
  end
  
  def add_category(opts = {})
    name = opts[:name]
    id = opts[:id]
    renamed = opts[:renamed] || false
    offset = opts[:offset]
    
    if category(name) or category(id)
      raise "Category already exists with that name or id!"
    end
    
    if @categories.length >= 16
      raise "Too many categories"
    end
    
    if id.nil?
      if @data.last_unique_id == 255
        # Find the first unused id
        category_ids = @categories.sort_by {|c| c.id }.collect {|c| c.id }
        0.upto(255) do |i|
          unless category_ids.include?(i)
            id = i
          end
        end
      else
        id = @data.last_unique_id + 1
        @data.last_unique_id = id
      end
    end
    
    if offset.nil?
      # Find first unused offset - either index of a nil slot, or next available.
      offset = @categories.index(nil) || @categories.length
    else
      unless @categories.index(offset).nil?
        raise "Offset of category already used!"
      end
    end

    c = PDB::AppInfo::Category.new(self, :name => name, :id => id, :renamed => renamed)
    @categories[offset] = c
    return c
  end
  
  def rename_category(old, new)
  end

  def renamed_categories()
    @categories.find_all {|c| c.renamed == true }
  end

  def length()
    unless @struct.nil?
      if @standard_appinfo == true
         @data.rest = @struct.to_s
      end
      return @data.length
    else
      return @data.length
    end
  end

end