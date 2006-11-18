#!/usr/bin/env ruby

require 'RubyPDB'
require 'date'

def convert_date(d)
  if (d != 0xffff)
    day = d & 0x001f
    month = (d >> 5) & 0x000f
    year = (d >> 9) & 0x07f
    year += 1904
    Date.new(year, month, day)
  end
end

class FuelRecord < RecordEntry
  def load
    stuff = @buffer.unpack("NNnNnZ")

    @data = {}
    @data['odometer'] = stuff[0]
    @data['gallons'] = stuff[1] / 1000.0
    @data['date'] = convert_date(stuff[2])
    @data['total_price'] = stuff[3] / 1000.0
    @data['flags'] = stuff[4]
    @data['notes'] = stuff[5]
  end

  def dump
    o = [@data['odometer'],
         @data['gallons'] * 1000,
         @data['date'],
         @data['total_price'] * 1000,
         @data['flags'],
         @data['notes']]
    @buffer = 2.pack("NNnNna")
  end
end

class FuelLog < PalmPDB
  def initialize()
    super()
    @recordclass = FuelRecord
  end

  def parse_app_info(data)
    # ... = data.unpack()

  end
end

a = FuelLog.new()
a.open_PDB_file("data/fuelLogDB.pdb")

# puts a.app_info.categories[1].name # 'Corolla'

total = 0
a.records.each { |r|
  puts "#{r.data['date']}\t#{r.data['gallons']}"
  total += r.data['total_price']
}

puts "Total: #{total}"
first = a.records.first.data['date']
last = a.records.last.data['date']
diff = last-first
puts "price/day: #{total / diff}"


