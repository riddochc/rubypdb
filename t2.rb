#!/usr/bin/env ruby

require 'yaml'
require 'stringio'
require 'date'

def serial_extract(io, format)
  data = {}
  format.each {|spec|
    unless spec['type'].nil?
      type = spec['type']
    else
      type = spec['unpack_type']
    end
    
    name = spec['name']
    count = spec['count']
    
    if type == 'variable_to_null'
      data[name] = io.gets("\x00")
      data[name].rstrip! # And yoink that null byte.
    else
      unpackstr = type
      unless count.nil?
        unpackstr += count.to_s
      end
      
      to_read = case type
                when 'Q': 8 # 64-bit
                when 'q': 8
                when 'D': 8 # float
                when 'E': 8
                when 'G': 8
                when 'I': 4 # integers
                when 'i': 4
                when 'L': 4
                when 'l': 4
                when 'N': 4
                when 'n': 4
                when 'V': 4
                when 'v': 4
                when 'e': 4 # float
                when 'f': 4
                when 'F': 4
                when 'g': 4
                when 's': 2
                when 'S': 2
                else count
                end

      if io.eof?
        puts "At end!"
        break
      end
      
      str = io.read(to_read)
      
      a = str.unpack(unpackstr)
      data[name] = a[0]
    end
  }

  return data
end

def serial_compact(format, data)
  output = ""
  format.each {|spec|
    unless spec['type'].nil?
      type = spec['type']
    else
      type = spec['pack_type']
    end
    name = spec['name']
    
    if type == 'variable_to_null'
      output += data[name] + "\0"
    else
      packstr = type
      
      unless spec['count'].nil?
        packstr += spec['count'].to_s
      end
      
      output += [data[name]].pack(packstr)
      puts "Output len: #{output.length}"
    end
  }
  return output
end
  
# stream = "\x0f\x00\x00\x00\x00\x01\x00\x00\x42\x6c\x61\x72\x67\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00This is a variable length string.\x0"
stream = "\x00\x01\xb7\x8b\x00\x00\x25\xcb\xca\xa8\x00\x00\x56\xe3\x00\x01\x00"

# 00 01 b7 8b - Odometer
# 00 00 25 cb - Gallons
# ca a8 00 00 - date
# 56 e3 - total price
# 00 01 - flags

io = StringIO.new(stream)

format = YAML.load(File.open("fuel_fmt.yaml"))

# data = serial_extract(io, format)

# compact_data = {'Foo' => 15, 'Bar' => 256, 'Blah' => "Blarg", 'Var' => "This is a variable-length string.", 'pi' => 3.14159265358979323}

# stuff = serial_compact(format, compact_data)

data = serial_extract(io, format)

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

data['date'] = convert_from_palm_date(data['date'])
data['gallons'] = data['gallons'] / 1000.0
data['total_price'] = data['total_price'] / 1000.0

# puts data.to_yaml

t = {}
t['total_price'] = 25000
t['date'] = convert_to_palm_date(Date.new(2005,10,13))
t['gallons'] = 95000
t['odometer'] = 120500
t['flags'] = 125

stuff = serial_compact(format, t)
print stuff

io2 = StringIO.new(stuff)
data2 = serial_extract(io2, format)

puts data2.to_yaml







               
