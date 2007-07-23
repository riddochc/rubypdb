require 'bit-struct'

class FuelLogRecord < BitStruct
  unsigned :odometer, 4*8
  unsigned :gallons, 4*8
  unsigned :date, 2*8
  unsigned :skip, 2*8
  unsigned :total_price, 2*8
  unsigned :flags, 2*8
end
