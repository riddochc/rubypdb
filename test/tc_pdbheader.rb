#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), '..', 'lib', 'pdb.rb')

require 'test/unit'

$datadir = File.join(File.dirname(__FILE__), 'data')

class PDBHeaderTest < Test::Unit::TestCase
  def test_read
    
    f = File.open($datadir + "/fuelLogDB.pdb")
    header_data = f.read(72)  # The magic number; the header's 72 bytes long.
    
    header = PDB::Header.new(header_data)
    puts header.inspect
  end
end