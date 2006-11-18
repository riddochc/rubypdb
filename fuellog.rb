#!/usr/bin/env ruby

require 'RubyPDB'
require 'lib/common.rb'

class FuelRecord < RecordEntry
  def initialize(*args)
    super(*args)
  end

  def post_load(main_class)
    @date = convert_from_palm_date(@date)
    @gallons = @gallons.to_i / (10.0 ** main_class.fuel_dec)
    @total_price = @total_price.to_i / (10.0 ** main_class.price_dec)
  end
end

eval make_dump_and_load("fuel_fmt.yaml")

class FuelLog < PalmPDB
  attr_accessor :fuel_dec, :price_dec, :odom_dec

  def initialize()
    super()
    @recordclass = FuelRecord
  end

  def parse_app_info(data)
    io = StringIO.new(data)
    buf = io.read()
    data = buf.unpack('snnn')
    @fuel_dec = data[2].to_i
    @price_dec = data[3].to_i
    @odom_dec = data[4].to_i
  end
end

a = FuelLog.new()
a.open_PDB_file("data/fuelLogDB.pdb")

# puts a.app_info.categories[1].name # 'Corolla'

total = 0
a.records.each { |r|
  puts "#{r.date}\t#{r.total_price}\t#{r.gallons}"
  total += r.total_price
}

puts "Total: #{total}"
first = a.records.first.date
last = a.records.last.date
diff = last-first
puts "price/day: #{total / diff}"

# puts a.records.to_yaml
