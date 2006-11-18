#!/usr/bin/env ruby

require 'RubyPDB'
require 'lib/common.rb'
require 'packstruct'

class FuelRecStruct < PackStruct
  field :odometer, 'N'
  field :gallons, 'N'
  field :date, 'n'
  field :price, 'N'
  field :flags, 'n'
  field :notes, 'a*'
end

class FuelRecord < RecordEntry
  attr_accessor :odometer, :gallons, :date, :price, :flags, :notes, :ppu

  def initialize(*args)
    super(*args)
  end

  def load(main_class)
    data = FuelRecStruct.new.unpack(@buffer)
    @odometer = data.odometer
    @gallons = data.gallons / (10.0 ** main_class.fuel_dec)
    @date = convert_from_palm_date(data.date)
    @price = data.price / (10.0 ** main_class.price_dec)
    @flags = data.flags
    @notes = data.notes
    @ppu = @price / @gallons
  end

  def db_schema()
    sql = <<_EOS_
create table fuellog (rid integer,
                      odometer integer,
                      gallons float,
                      date float,
                      price float,
                      flags integer,
                      notes text);
_EOS_
  end

  def to_sql(db, rid)
    db.execute("insert into fuellog (rid, odometer, gallons, date, price, flags, notes) values (?, ?, ?, ?, ?, ?, ?);", rid, @odometer, @gallons, @date, @price, @flags, @notes)
   super(db)
  end
end

# eval make_dump_and_load("fuel_fmt.yaml")

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
  puts "#{r.date}\t#{r.odometer}\t#{r.price}\t#{r.gallons}\t#{r.ppu}"
  total += r.price
}

#puts "Total: #{total}"
#first = a.records.first.date
#last = a.records.last.date
#diff = last-first
#puts "price/day: #{total / diff}"

# puts a.records.to_yaml


