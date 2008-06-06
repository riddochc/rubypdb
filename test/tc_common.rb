#!/usr/bin/env ruby

require 'rubypdb.rb'
require 'test/unit'

class GetConstFromStringTest < Test::Unit::TestCase
  def test_string
    assert_equal "String".get_full_const, String
    assert_nil "NonExistentClass".get_full_const
  end

  def test_from_core_pdb_classes
    assert_equal "PDB".get_full_const, PDB
    assert_equal "PDB::FuelLog::Record::Struct".get_full_const, PDB::FuelLog::Record::Struct
  end
end
