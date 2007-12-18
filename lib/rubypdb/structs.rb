require 'bit-struct'

module PDB
end

class PDB::AttributeFlags < BitStruct
  unsigned :open,       1   #0x8000
  unsigned :unk_3,      1   #0x4000
  unsigned :unk_2,      1   #0x2000
  unsigned :unk_1,      1   #0x1000
  unsigned :bundle,     1   #0x0800
  unsigned :recyclable, 1   #0x0400
  unsigned :launchable, 1   #0x0200
  unsigned :hidden,     1   #0x0100
  unsigned :stream,     1   #0x0080
  unsigned :copy_prev,  1   #0x0040
  unsigned :reset,      1   #0x0020
  unsigned :newer_ok,   1   #0x0010
  unsigned :backup,     1   #0x0008
  unsigned :dirty,      1   #0x0004
  unsigned :read_only,  1   #0x0002
  unsigned :resource,   1   #0x0001
end

class PDB::ResourceIndex < BitStruct
  unsigned :next_index, 8 * 4
  unsigned :number_of_records,    8 * 2
end

class PDB::Header < BitStruct
  text     :name,       8 * 32
  nest     :attributes, PDB::AttributeFlags
  unsigned :version,    8 * 2
  unsigned :ctime,      8 * 4
  unsigned :mtime,      8 * 4
  unsigned :baktime,    8 * 4
  unsigned :modnum,     8 * 4
  unsigned :appinfo_offset,   8 * 4
  unsigned :sortinfo_offset,  8 * 4
  text     :type,       8 * 4
  text     :creator,    8 * 4
  unsigned :uniqueid,   8 * 4
  nest     :resource_index, PDB::ResourceIndex
end

class PDB::Resource < BitStruct
  text     :type,   8 * 4
  unsigned :r_id,     8 * 2
  unsigned :offset, 8 * 4
end

class PDB::RecordAttributes < BitStruct
  unsigned :delete, 1  # 0x080
  unsigned :dirty,  1  # 0x040
  unsigned :busy,   1  # 0x020
  unsigned :secret, 1  # 0x010
  unsigned :category,  4  # 0x008 - 0x001
end

class PDB::Record < BitStruct
  unsigned :offset, 8 * 4
  nest     :attributes,  PDB::RecordAttributes
  unsigned :r_id,     8 * 3
end

class PDB::StandardAppInfoBlock < BitStruct
  unsigned  :renamed_categories,  8 * 2
  16.times do |i|
    text      "category_name[#{i}]".to_sym,  8 * 16
  end
  16.times do |i|
    unsigned  "category_id[#{i}]".to_sym, 8 * 1
  end
  unsigned :last_unique_id, 8 * 1
  rest     :rest
end
