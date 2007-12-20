#!/usr/bin/env ruby

require 'rubypdb.rb'

require 'test/unit'
require 'yaml'
require 'parsedate'
require 'stringio'
require 'tempfile'

$datadir = File.join(File.dirname(__FILE__), 'data')

class PDBRecordTest < Test::Unit::TestCase
  def test_load
    a = PDB::FuelLog.new()
    f = File.open($datadir + "/fuelLogDB.pdb")
    a.load(f)
    puts a.appinfo.struct.to_yaml
    puts
    a.each {|r|
      puts "Date: #{r.date}"
      puts "Odometer: #{r.odometer}"
      puts "Gallons: #{r.gallons}"
      puts "Price: #{r.price}"
      puts "Filled tank: #{r.fulltank}"
      # puts "Notes: #{r.notes}"
      puts
    }
  end
end