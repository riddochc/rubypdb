#!/usr/bin/env ruby

require 'rubypdb.rb'

require 'test/unit'
require 'yaml'
require 'parsedate'
require 'stringio'
require 'tempfile'

$datadir = File.join(File.dirname(__FILE__), 'data')

class PDBYamlTest < Test::Unit::TestCase
  def test_compare_yaml
    a = PDB::FuelLog.new()
    f = File.open($datadir + "/fuelLogDB.pdb")
    a.load(f)
    src_yaml = a.to_yaml
    dest_yaml = File.open($datadir + "/fuelLogDB.yaml").read(nil)

    # File.open($datadir + '/test-out.yaml', 'w') {|f| f.write(a.to_yaml) }
    assert src_yaml.to_s == dest_yaml.to_s
  end

  def test_compare_pdbs
    a = PDB::FuelLog.new()
    f = File.open($datadir + "/fuelLogDB.pdb")
    a.load(f)

    b = YAML.load(File.open($datadir + "/fuelLogDB.yaml"))

    a_io = StringIO.new()
    a.dump(a_io)
    
    b_io = StringIO.new()
    b.dump(b_io)
    
    assert a_io.read() == b_io.read()
  end
end