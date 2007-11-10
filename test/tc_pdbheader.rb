#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), '..', 'lib', 'pdb.rb')

require 'test/unit'
require 'yaml'
require 'parsedate'

$datadir = File.join(File.dirname(__FILE__), 'data')

class PDBHeaderTest < Test::Unit::TestCase
  def test_read
    a = PalmPDB.new()
    f = File.open($datadir + "/fuelLogDB.pdb")
    a.load(f)
    puts a.header.inspect
    #puts a.appinfo.inspect
    #a.each {|i, r|
      #puts i.to_yaml
      #puts FuelLogRecord.new(r).to_yaml
    #}
    # Did the parse work?
    assert a.index.length == a.header.resource_index.number_of_records
    assert a.records.length == a.header.resource_index.number_of_records
    assert a.header.resource_index.number_of_records = 21

    assert a.ctime == Time.local(*ParseDate.parsedate("2005-06-14 03:02:09"))
    assert a.mtime == Time.local(*ParseDate.parsedate("2005-11-02 18:34:27"))
    assert a.backup_time == Time.local(*ParseDate.parsedate("2005-10-07 03:52:39"))
    assert a.header.attributes.backup == 1
    assert a.header.attributes.read_only == 0
  end
end