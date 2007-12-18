#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), '..', 'lib', 'pdb-formats', 'fuellog.rb')

require 'test/unit'

class BitStructTest < Test::Unit::TestCase

  def test_bitstruct

    entry_hexdump = %w{00 01 b7 8b 00 00 25 cb ca a8 00 00 56 e3 00 01 00}
    entry = entry_hexdump.inject("") {|string, hex| string << hex.to_i(16).chr}

    actual = {:odometer => 112523, :gallons => 9675,
              :date => convert_to_palm_date(Date.new(2005, 5, 8)),
              :total_price => 22243, :flags => 1}

    unpacked = entry.unpack("NNnnnn")
    odometer = unpacked[0]
    gallons = unpacked[1]
    date = unpacked[2]
    total_price = unpacked[4]
    flags = unpacked[5]

    assert_equal odometer, actual[:odometer]
    assert_equal gallons, actual[:gallons]
    assert_equal date, actual[:date]
    assert_equal total_price, actual[:total_price]
    assert_equal flags, actual[:flags]

    fuel_entry = FuelLogRecord.new(entry)

    assert_equal fuel_entry.odometer, actual[:odometer]
    assert_equal fuel_entry.gallons, actual[:gallons]
    assert_equal fuel_entry.date, actual[:date]
    assert_equal fuel_entry.total_price, actual[:total_price]
    assert_equal fuel_entry.flags, actual[:flags]
  end
end
