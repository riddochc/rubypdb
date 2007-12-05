require 'date'
require 'stringio'
require 'bit-struct'
require 'delegate'

class Time
  @@epoch_1904 = 2082844800

  def self.from_palm(secs)
    self.at(secs - @@epoch_1904)
  end

  def to_palm()
    @@epoch_1904 + self.to_i
  end 
end


class Date
  def self.from_palm(num)
    if (num != 0xffff)
      day = num & 0x001f
      month = (num >> 5) & 0x000f
      year = (num >> 9) & 0x07f
      year += 1904
      Date.new(year, month, day)
    else
      nil
    end
  end

  def to_palm()
    pd = (self.day & 0x001f) |
       ((self.month & 0x000f) << 5) |
       (((self.year - 1904) & 0x007f) << 9)
    return pd
  end
end

class String
  def hexdump(params)
    offset = params[:offset] || 0
    width = params[:width] || 16
    result = []
    while raw = self.slice(offset, width) and raw.length > 0
      # address field
      line = sprintf("%08x  ", offset)

      # data field
      raw.each_byte {|c|
        line << sprintf("%02x ", c)
      }

      line << (" " * (((width - raw.length) * 3) + 4))
      # text field
      line <<  raw.tr("\000-\037\177-\377", ".")

      result << line
      offset += width
    end
    result.join("\n")
  end
  
  def to_hex(prefix = true)
    if prefix == true
      hex = "0x"
    else
      hex = ""
    end
    self.each_byte do |b|
      hex << ("%x" % b)
    end
    hex
  end
end
