#!/usr/bin/env ruby

require 'rubypdb.rb'

require 'test/unit'
require 'yaml'
require 'parsedate'
require 'stringio'
require 'tempfile'

$datadir = File.join(File.dirname(__FILE__), 'data')

class RegressionTest < Test::Unit::TestCase
  def test_bug_1
    a = PDB::FuelLog.new()
    f = File.open($datadir + "/fuelLogDB.pdb")
    a.load(f)

    # Doesn't matter which one, really.  The records are being loaded all wrong...
    rec = a.records[249859]

    # This exception is what first drew my attention to the problem.
    assert_nothing_raised(ArgumentError) { rec.date }
    assert_not_equal rec.struct.date, 0
    assert_not_equal rec.odometer, 534
    assert_not_equal rec.total_price, 0.0
    assert_not_equal rec.gallons, 1090768.899
    assert_not_equal rec.fulltank, false
  end
end