# This is code for manipulating AppInfo structures at a higher-level.

module PDB
end

# Higher-level interface to PDB::StandardAppInfoBlock
class PDB::AppInfo
  attr_accessor :struct, :standard_appinfo, :data
  attr_reader :categories

  def initialize(standard_appinfo, pdb, *rest)
    @standard_appinfo = standard_appinfo
    @pdb = pdb
    data = rest.first

    unless data.nil?
      load(data)
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