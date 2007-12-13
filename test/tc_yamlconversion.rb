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
  def test_load
    a = PDB::FuelLog.new()
    f = File.open($datadir + "/fuelLogDB.pdb")
    a.load(f)
    src_yaml = a.to_yaml
    dest_yaml = YAML.load(File.open($datadir + "/fuelLogDB.yaml"))

    puts src_yaml

    assert src_yaml == dest_yaml
  end
end