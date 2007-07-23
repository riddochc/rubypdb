#!/usr/bin/env ruby

require 'rubygems'
require 'stringio'
require_gem 'ruby-debug'

def hexdump(str)
  offset = 0
  result = []

  while raw = str.slice(offset, 16) and raw.length > 0
    # address field
    line = sprintf("%08x  ", offset)

    # data field
    raw.each_byte {|c|
      line << sprintf("%02x ", c)
    }

    line << (" " * (((16 - raw.length) * 3) + 4))
    # text field
    line <<  raw.tr("\000-\037\177-\377", ".")

    result << line
    offset += 16
  end
  result
end

class String
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

def read_integer(io, count, signed)
  if signed == true
    unpacker = "c"
  else
    unpacker = "C"
  end
  puts "Unpacking with: #{unpacker + count.to_s}"
  value = io.read(count).unpack(unpacker + count.to_s).first
  return value
end


def write_string(io, data, options)
  width = options[:width] || data.length
  padding = options[:padding] || :space
  encoding = options[:encoding] || :ascii

  case encoding
  when :ascii
    if padding == :null
      packing = 'a'
    elsif padding == :space
      packing = 'A'
    end
  when :mime
    packing = 'M'
  when :base64
    packing = 'm'
  when :uu
    packing = 'u'
  end

  if encoding == :ascii
    full_packing = packing + width.to_s
  else
    full_packing = packing
  end

  io.write([data].pack(full_packing))
end

io = StringIO.new()

write_string(io, "a", :width => "3", :encoding => :ascii, :padding => :null)
write_string(io, "b", :width => "3", :encoding => :ascii)
write_string(io, "This string is too long", :width => 7, :encoding => :ascii)



io.pos=0
out = io.gets(nil)
puts hexdump(out)

puts "Done debugging."