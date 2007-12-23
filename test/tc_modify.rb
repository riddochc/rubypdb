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
    r.date = Date.today
    r.fulltank = true
    r.category = "Corolla"

    db << r
    db.recompute_offsets

    tf = Tempfile.new('pdbtest')
    tf_dump = Tempfile.new('new_dump')
    db.dump(tf)
    tf.close

    orig_dump = Tempfile.new('orig_dump')
    original = `pilot-file -d #{$datadir + "/fuelLogDB.pdb"} > #{orig_dump.path}`

    recreated = `pilot-file -d #{tf.path} > #{tf_dump.path}`
    diff = `diff #{orig_dump.path} #{tf_dump.path}`

    correct_diff =<<_EOD_
118a119,121
> 21\t16\t0x0\t1\t0x3d01b
> 0000: 00 02 22 e0 00 00 27 d8 cf 97 00 00 76 2a 00 01   .."`..'XO...v*..
> 
_EOD_

    assert diff == correct_diff
  end

end