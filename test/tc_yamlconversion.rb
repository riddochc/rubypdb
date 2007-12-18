#!/usr/bin/env ruby

# require File.join(File.dirname(__FILE__), '..', 'lib', 'pdb.rb')
require File.join(File.dirname(__FILE__), '..', 'lib', 'pdb-formats', 'fuellog.rb')

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

    assert src_yaml.to_s == dest_yaml.to_s
  end

  def test_compare_pdbs
    a = PDB::FuelLog.new()
    f = File.open($datadir + "/fuelLogDB.pdb")
    a.load(f)

    b = YAML.load(File.open($datadir + "/fuelLogDB.yaml"))

    assert a == b
  end
end