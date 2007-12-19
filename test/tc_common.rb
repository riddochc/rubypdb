#!/usr/bin/env ruby

require 'rubypdb.rb'
require 'test/unit'

class GetConstFromStringTest < Test::Unit::TestCase
  def test_string
    c = Kernel.const_get_from_string("String")
    assert c == String
    assert_raise(NameError) do
      n = Kernel.const_get_from_string("NonExistentClass")
    end
  end

  def test_from_core_pdb_classes
    c = Kernel.const_get_from_string("PDB")
    assert c == PDB
    c = Kernel.const_get_from_string("PDB::FuelLog::Record::Struct")
    assert c == PDB::FuelLog::Record::Struct
  end
end
