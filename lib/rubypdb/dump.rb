# This is code related to writing structures out to the binary formats.

module PDB
end

class PDB::AppInfo
  def dump()
    unless @struct.nil?
      if @standard_appinfo == true
        @data.rest = @struct.to_s
      end
      return @data.to_s
    else
      return @data
    end
  end
end

class PDB::Data
  def dump()
    unless @struct.nil?
      return @struct.to_s
    else
      return @data
    end
  end
end

class PalmPDB
  def dump(f)
    recompute_offsets()
    f.write(@header)

    @index.each do |i|
      f.write(i)
    end

    unless @appinfo.nil?
      f.write(@appinfo.dump())
    end

    unless @sortinfo.nil?
      f.write(@sortinfo.dump())
    end

    @index.each do |i|
      record = @records[i.r_id]
      f.write(record.dump())
    end
  end
end
