require 'date'
require 'stringio'
require 'bit-struct'
require 'delegate'

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


class PalmDate < DelegateClass(Date)
  def initialize(*rest)
    if rest.length == 1
      load(rest.first)
    else
      super(Date.new(*rest))
    end
  end

  def load(io)
    if io.kind_of? Integer
      from_palm(io)
    else
      if io.respond_to? :read
        data = io.read(2)
      elsif io.respond_to? :length
        data = io
      end
      from_palm(data.unpack('n')[0])
    end
  end

  def dump(io = nil)
    out = [to_palm()].pack('n')
    if io.respond_to? :write
      io.write(out)
    end
    return out
  end

  def from_palm(num)
    if (num != 0xffff)
      day = num & 0x001f
      month = (num >> 5) & 0x000f
      year = (num >> 9) & 0x07f
      year += 1904
      self.__setobj__(Date.new(year, month, day))
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
