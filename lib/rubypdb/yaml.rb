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
            unless c['name'] == ""
              cats << c
            end
          end
          map.add('Categories', cats)
          map.add('Renamed_categories', self.data.renamed_categories)
          map.add('Last_unique_id', self.data.last_unique_id)
          map.add('Custom_Appinfo_Data', self.struct)
        else
          map.add('Data', @data)
        end
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

    puts "Parsing: #{pdb_name}, #{pdb_type}"

    st = pdb_type.new
    st.header.name = val['Name']
    st.header.type = val['Type']
    st.header.creator = val['Creator'] || 'palm'
    st.header.version = val['Version'] || 0
    st.ctime = val['Creation_time'] || Time.now
    st.mtime = val['Modification_time'] || Time.now
    st.backup_time = val['Backup_time'] || Time.now
    st.header.modnum = val['Mod_number'] || 0
    st.header.uniqueid = val['Unique_ID'] || 0
    st.header.resource_index.next_index = val['Next_index'] || 0

    st.header.attributes = val['Flags']
    st.appinfo = val['AppInfo']
    st.sortinfo = val['SortInfo']
    # st.records = val['Records']

    st.recompute_offsets
    st 
  end
end