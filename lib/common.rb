require 'date'
require 'stringio'
require 'bit-struct'

def convert_from_palm_date(d)
  if (d != 0xffff)
    day = d & 0x001f
    month = (d >> 5) & 0x000f
    year = (d >> 9) & 0x07f
    year += 1904
    Date.new(year, month, day)
  end
end

def convert_to_palm_date(d)
  pd = (d.day & 0x001f) |
       ((d.month & 0x000f) << 5) |
       (((d.year - 1904) & 0x007f) << 9)
  return pd
end
