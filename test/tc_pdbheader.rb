#!/usr/bin/env ruby

# require File.join(File.dirname(__FILE__), '..', 'lib', 'rubypdb', 'pdb.rb')
require File.join(File.dirname(__FILE__), '..', 'lib', 'pdb-formats', 'fuellog.rb')

require 'test/unit'
require 'yaml'
require 'parsedate'
require 'stringio'
require 'tempfile'

$datadir = File.join(File.dirname(__FILE__), 'data')

class PDBHeaderTest < Test::Unit::TestCase
  def test_load
    a = PDB::FuelLog.new()
    f = File.open($datadir + "/fuelLogDB.pdb")
    a.load(f)
    assert a.index.length == a.header.resource_index.number_of_records
    assert a.records.length == a.header.resource_index.number_of_records
    assert a.header.resource_index.number_of_records = 21

    assert a.ctime == Time.local(*ParseDate.parsedate("2005-06-14 03:02:09"))
    assert a.mtime == Time.local(*ParseDate.parsedate("2005-11-02 18:34:27"))
    assert a.backup_time == Time.local(*ParseDate.parsedate("2005-10-07 03:52:39"))
    assert a.header.attributes.backup == 1
    assert a.header.attributes.read_only == 0
  end

  def test_load_and_dump
    a = PDB::FuelLog.new()
    testfile = $datadir + "/fuelLogDB.pdb"
    f = File.open(testfile)

    a.load(f)
    tf = Tempfile.new('pdbtest')
    a.dump(tf)
    tf.close

    puts
    puts `hexdump -C #{tf.path}`
    recreated = `pilot-file -d #{tf.path}`
    puts recreated
    original = `pilot-file -d #{testfile}`
    assert recreated == original
  end

  def test_dump_from_clone()
    pdb = PDB::FuelLog.new
    pdb.header.name = 'fuelLogDB'
    pdb.header.attributes.backup = 1
    pdb.header.version = 0
    pdb.ctime = Time.local(*ParseDate.parsedate("2005-06-14 03:02:09"))
    pdb.mtime = Time.local(*ParseDate.parsedate("2005-11-02 18:34:27"))
    pdb.backup_time = Time.local(*ParseDate.parsedate("2005-10-07 03:52:39"))
    pdb.header.modnum = 171
    pdb.header.type = 'Data'
    pdb.header.creator = 'dpa1'
  end
end
