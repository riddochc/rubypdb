#!/usr/bin/env ruby

require 'rubypdb.rb'

require 'test/unit'
require 'yaml'
require 'parsedate'
require 'stringio'
require 'tempfile'

$datadir = File.join(File.dirname(__FILE__), 'data')

class PDBModifyingTest < Test::Unit::TestCase
  def test_insert_record
    db = PDB::FuelLog.new()
    f = File.open($datadir + "/fuelLogDB.pdb")
    db.load(f)

    r = PDB::FuelLog::Record.new(db)
    r.odometer = 140000
    r.gallons = 10.2
    r.price = 30.25
    r.date = Date.new(2007, 12, 28)
    r.fulltank = true
    r.category = "Corolla"

    db << r
    db.recompute_offsets

    tf = Tempfile.new('pdbtest')
    db.dump(tf)
    tf.close
    tf_dump = Tempfile.new('pdbdump')
    
    orig_dump = Tempfile.new('orig_dump')
    original = `pilot-file -d #{$datadir + "/fuelLogDB.pdb"} > #{orig_dump.path}`

    recreated = `pilot-file -d #{tf.path} > #{tf_dump.path}`
    diff = `diff #{orig_dump.path} #{tf_dump.path}`

    correct_diff =<<_EOD_
118a119,121
> 21\t16\t0x0\t1\t0x3d01b
> 0000: 00 02 22 e0 00 00 27 d8 cf 9c 00 00 76 2a 00 01   .."`..'XO...v*..
> 
_EOD_

    assert diff == correct_diff
    assert $?.exitstatus == 1  # Diff shows a difference

    db.delete(r.metadata.r_id)
    db.recompute_offsets
    # puts db.to_yaml
  
    tf = Tempfile.new('orig_cpy')
    db.dump(tf)
    tf.close
  
    tf_dump = Tempfile.new('orig_cpy_dump')

    recreated = `pilot-file -d #{tf.path} > #{tf_dump.path}`
    diff = `diff #{orig_dump.path} #{tf_dump.path}`

    assert diff == ""
    assert $?.exitstatus == 0  # Diff shows no difference
  end

  def test_set_array_of_records
    a = PDB::FuelLog::Record.new(@db)
    a.odometer = 140000
    a.gallons = 10.2
    a.price = 30.25
    a.date = Date.new(2007, 12, 28)
    a.fulltank = true
    a.category = "Corolla"
    
    b = PDB::FuelLog::Record.new(@db)
    b.odometer = 140300
    b.gallons = 10.1
    b.price = 28.75
    b.date = Date.new(2008, 1, 11)
    b.fulltank = true
    b.category = "Corolla"
    
    new_data = [a, b]
    
    @db.records = new_data
    assert @db.records.length == 2
    assert @db.records[1].odometer == a.odometer
    assert @db.records[2].odometer == b.odometer
    
    @db.delete(1)
    assert @db.records.length == 1
  end
end