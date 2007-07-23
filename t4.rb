#!/usr/bin/env ruby

require 'yaml'
require 'stringio'

module PalmRecord
  @@class_data = {}

  def field(name, type, *options, &block)

    stuff = case(type)
      when :number
         # Read a number
        [lambda {|io|
           value = io.read(1).unpack("C").first
           return value
         },
         # Write a number
         lambda {|io, data|
            io.write([data].pack("C"))
         }]
      when :string
         # Read a fixed-width string
        [lambda {|io| 
           length = options[0] # Always the first optional param
           string = io.read(length)
           return string
         },
         # Write a fixed-width string
         lambda {|io, data|
           length = options[0]
           count = io.write(data)
           if count != length
             throw "Didn't write the correct length!"
           end
         }]
    end

    reader = stuff[0]
    writer = stuff[1]
    define_method(name.to_s + "_reader", reader)
    define_method(name.to_s + "_writer", writer)

    if @@class_data[self].nil?
      @@class_data[self] = {}
    end

    fields = @@class_data[self][:fields]
    if fields.nil?
      fields = []
    end
    fields << name
    @@class_data[self][:fields] = fields
  end

  def each_field()
    @@class_data[self.class][:fields].each {|field|
      yield field
    }
  end
end


class PalmHelpers

  def load_data(sio)
    each_field() { |f|
      value = send(f.to_s + "_reader", sio)
      instance_variable_set("@" + f.to_s, value)
    }
  end

  def dump_data(sio)
    each_field() { |f|
      value = instance_variable_get("@" + f.to_s)
      send(f.to_s + "_writer", sio, value)
    }
  end
end

class FuelLog < PalmHelpers
  include PalmRecord
  extend PalmRecord
  attr_accessor :one, :two, :three

  field :one, :number
  field :two, :string, 9
  field :three, :number

end

sio = StringIO.new("\x70Some text\x31")

f = FuelLog.new()
f.load_data(sio)

puts "One is #{f.one}"
puts "Two is: #{f.two}"
puts "Three is: #{f.three}"
puts "---"

out = StringIO.new()
f.dump_data(out)
out.pos = 0
puts "Out: #{out.read()}"

#f.one_reader(sio)
#f.two_reader(sio)
#f.three_reader(sio)


#a = StringIO.new("")
#af = FuelLog.new()
#af.bar_writer(a, 250)
#puts "StringIO is now: #{a.read()}"



#f.field :foo, :string
