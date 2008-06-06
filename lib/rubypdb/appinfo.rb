# This is code for manipulating AppInfo structures at a higher-level.

module PDB
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

  # If val is an integer, find the string for the category at that index.
  # If it's a string, return the index of the category with that name.
  def category(val)
    if val.is_a? Integer
      return @categories[val]['name']
    else
      found = nil
      @categories.each_with_index do |c, i|
        if c['name'] == val
          found = i
          break
        end
      end

      return found
    end
  end

  def new_category(name)
    puts "Making new category called #{name}"
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