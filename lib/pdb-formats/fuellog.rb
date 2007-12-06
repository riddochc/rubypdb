require 'bit-struct'

require File.join(File.dirname(__FILE__), '..', 'pdb')
require File.join(File.dirname(__FILE__), '..', 'common')


class PDB::FuelLog < PalmPDB
end

class PDB::FuelLog::AppInfo < PDB::AppInfo
  def initialize(*rest)
    super(true, *rest)  # Uses standard categories.
  end
end

class PDB::FuelLog::AppInfo::Struct < BitStruct
  unsigned :fuel_volume, 8   #  0 = miles, 1 = kilometers
  unsigned :distance_units, 8  #  0 = litres, 1 = gallons, 2 = US gallons
  unsigned :efficiency_units, 8 #  0 = Miles/Gal, 1 = L/100km, 2 = km/L, 3 = km/gal
  unsigned :category, 2*8
  unsigned :fuel_dec, 2*8
  unsigned :price_dec, 2*8
  unsigned :odom_dec, 2*8
end

class PDB::FuelLog::Record < PDB::Data
  def gallons
    @struct.gallons.to_f / (10 ** @pdb.appinfo.struct.fuel_dec)
  end

  def price
    @struct.total_price.to_f / (10 ** @pdb.appinfo.struct.price_dec)
  end

  def date
    Date.from_palm(@struct.date)
  end

  def odometer
    @struct.odometer
  end

  def fulltank
    @struct.fulltank
  end

  def notes
    @struct.notes
  end
end

class PDB::FuelLog::Record::Struct < BitStruct
  unsigned :odometer, 4*8
  unsigned :gallons, 4*8
  unsigned :date, 2*8
  unsigned :total_price, 4*8
  unsigned :fulltank, 2*8
  rest :notes
end
