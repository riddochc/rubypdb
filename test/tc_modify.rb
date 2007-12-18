#!/usr/bin/env ruby

# require File.join(File.dirname(__FILE__), '..', 'lib', 'rubypdb', 'pdb.rb')
require File.join(File.dirname(__FILE__), '..', 'lib', 'pdb-formats', 'fuellog.rb')

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
    
    puts r.to_yaml
    # db << r
    
    # puts db.to_yaml
  end

end