module PDB
end

class PDB::FuelLog < PalmPDB
  def initialize()
    super(:appinfo_class => PDB::FuelLog::AppInfo,
          :sortinfo_class => PDB::FuelLog::SortInfo,
          :data_class => PDB::FuelLog::Record)
  end
end

class PDB::FuelLog::AppInfo < PDB::AppInfo
  def initialize(*rest)
    super(true, *rest)  # Uses standard categories.
  end
end

class PDB::FuelLog::SortInfo
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

  def odometer
    @struct.odometer
  end

  def odometer=(val)
    @struct.odometer = val.to_i
  end

  def gallons
    @struct.gallons.to_f / (10 ** @pdb.appinfo.struct.fuel_dec)
  end

  def gallons=(val)
    @struct.gallons = val.to_f * (10 ** @pdb.appinfo.struct.fuel_dec)
  end

  def price
    @struct.total_price.to_f / (10 ** @pdb.appinfo.struct.price_dec)
  end

  def price=(val)
    @struct.total_price = val.to_f * (10 ** @pdb.appinfo.struct.price_dec)
  end

  def date
    Date.from_palm(@struct.date)
  end

  def date=(d)
    @struct.date = d.to_palm
  end

  def fulltank
    @struct.fulltank
  end

  def fulltank=(val)
    if ((val == 0) or (val == false))
      @struct.fulltank = 0
    else
      @struct.fulltank = 1
    end
  end

  def notes
    @struct.notes
  end

  def notes=(val)
    @struct.notes = val + "\0"
  end

  def to_yaml(opts = {})
    YAML::quick_emit( self.object_id, opts ) do |out|
      out.map( to_yaml_style ) do |map|
        map.add('Date', self.date)
        map.add('Odometer', self.odometer)
        map.add('Total_Price', self.price)
        map.add('Gallons', self.gallons)
        if @struct.fulltank == 1
          map.add('Full_tank', true)
        else
          map.add('Full_tank', false)
        end
        map.add('Metadata', self.metadata)
      end
    end
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
