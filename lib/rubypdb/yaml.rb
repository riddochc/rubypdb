require 'yaml'

class PDB::AppInfo
  yaml_as "tag:syntacticsugar.org,2007:palm_appinfo"

  def to_yaml(opts = {})
    YAML::quick_emit( self.object_id, opts ) do |out|
      out.map( to_yaml_style ) do |map|
        map.add('Standard_appinfo', self.standard_appinfo)
        if self.standard_appinfo == true
          cats = []
          self.categories.each do |c|
            cats << c
          end
          map.add('Categories', cats)
          map.add('Last_unique_id', self.data.last_unique_id)
          map.add('Custom_Appinfo_Data', self.struct)
        else
          map.add('Data', @data)
        end
      end
    end
  end
  
  def new_from_yaml(val)
    if ((@standard_appinfo == true) or (val['Standard_appinfo'] == true))
      @struct = val['Custom_Appinfo_Data']
      
      @data = PDB::StandardAppInfoBlock.new
      @data.last_unique_id = val['Last_unique_id']
      
      renamed = 0
      val['Categories'].each_with_index do |cat, i|
        add_category(:offset => i, :name => cat.name,
                     :id => cat.id, :renamed => cat.renamed)
        if (cat.renamed == true)
          renamed = renamed + (2 ** i)
        end
      end
      @data.renamed_categories = renamed
      
      @data.rest = @struct
    else 
      @data = val['Data']
    end
  end
end

class PDB::SortInfo
  yaml_as "tag:syntacticsugar.org,2007:palm_sortinfo"
end

class PDB::Record
  # default to_yaml here is overridden so that offset isn't written out.
  def to_yaml(opts = {})
    YAML::quick_emit( self.object_id, opts ) do |out|
      out.map(to_yaml_style) do |map|
        map.add('attributes', self.attributes)
        map.add('r_id', self.r_id)
      end
    end
  end
end

class PDB::Resource
  # default to_yaml here is overridden so that offset isn't written out.
  def to_yaml(opts = {})
    YAML::quick_emit( self.object_id, opts ) do |out|
      out.map(to_yaml_style) do |map|
        map.add('type', self.type)
        map.add('r_id', self.r_id)
      end
    end
  end
end

class PDB::Data
  def to_yaml(opts = {})
    
  end
  
  def new_from_yaml(yaml_data)
    unless Hash === yaml_data
      raise YAML::TypeError, "Invalid record: " + yaml_data.inspect
    end
    
    yaml_data.each_pair do |key, value|
      unless key == 'metadata'
        self.send("#{key}=".to_sym, value)  # Run "self.key = value"
      end
    end
  end
end

class PalmPDB
  yaml_as "tag:syntacticsugar.org,2007:#{self}", true

  def to_yaml(opts = {})
    YAML::quick_emit( self.object_id, opts ) do |out|
      out.map( taguri, to_yaml_style ) do |map|
        map.add('Name', self.header.name)
        map.add('Type', self.header.type)
        map.add('Creator', self.header.creator)
        map.add('Version', self.header.version)
        map.add('Creation_time', self.ctime)
        map.add('Modification_time', self.mtime)
        map.add('Backup_time', self.backup_time)
        map.add('Mod_number', self.header.modnum)
        map.add('Unique_ID', self.header.uniqueid)
        map.add('Next_index', self.header.resource_index.next_index)
        map.add('Flags', self.header.attributes)
        map.add('AppInfo', self.appinfo) unless self.appinfo == nil
        map.add('SortInfo', self.sortinfo) unless self.sortinfo == nil
        map.add('Records', self.records.values)
      end
    end
  end

  def self.yaml_new( klass, tag, val) # :nodoc:
    unless Hash === val
      raise YAML::TypeError, "Invalid PDB: " + val.inspect
    end

    pdb_name, pdb_type =  YAML.read_type_class( tag, PalmPDB)

    pdb = pdb_type.new
    pdb.header.name = val['Name']
    pdb.header.type = val['Type']
    pdb.header.creator = val['Creator'] || 'palm'
    pdb.header.version = val['Version'] || 0
    pdb.ctime = val['Creation_time'] || Time.now
    pdb.mtime = val['Modification_time'] || Time.now
    pdb.backup_time = val['Backup_time'] || Time.now
    pdb.header.modnum = val['Mod_number'] || 0
    pdb.header.uniqueid = val['Unique_ID'] || 0
    pdb.header.resource_index.next_index = val['Next_index'] || 0

    pdb.header.attributes = val['Flags']
    
    appinfo = pdb.appinfo_class.new(pdb)
    appinfo.new_from_yaml(val['AppInfo'])
    pdb.appinfo = appinfo

    #@sortinfo = pdb.sortinfo_class.new(self)
    #@sortinfo.set_from_yaml_hash(val['SortInfo'])

    data_class = pdb.data_class
    
    pdb.records = {}
    val['Records'].each {|yaml_rec|
      rec = data_class.new(pdb)
      rec.new_from_yaml(yaml_rec)
      
      metadata = rec.metadata_class.new()
      metadata.r_id = yaml_rec['metadata']['r_id']
      metadata.attributes = yaml_rec['metadata']['attributes']
      rec.metadata = metadata

      pdb.records[rec.metadata.r_id] = rec
    }

    pdb.recompute_offsets
    pdb
  end
end