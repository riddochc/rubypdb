#!/usr/bin/env ruby

require 'yaml'
require 'stringio'
require 'erb'


def make_dump_and_load(file)
  type_sizes = Hash.new(nil)
  ['Q', 'q', 'D', 'E', 'G'].each {|x| type_sizes[x] = 8}
  ['I', 'i', 'L', 'l', 'N', 'n', 'V', 'v', 'e', 'f', 'F', 'g'].each {|x| type_sizes[x] = 4}
  ['s', 'S'].each {|x| type_sizes[x] = 2}
  
  fmt = YAML.load_file(file)
  
  data = <<_EOS_
class <%= fmt['class'] %>
  def load()
    io = StringIO.new(@buffer)
% fmt['struct'].each { |f|
%  type_size = type_sizes[f['type']]
%  unless type_size.nil?
    buf = io.read(<%= type_size %>) # <%= f['name'] %>
    @<%= f['name'] %> = buf.unpack('<%= f['type'] %>')[0]
%  else
%    unless f['count'].nil?
    buf = io.read(<%= f['count'] %>) # <%= f['name'] %> (fixed-width)
    @<%= f['name'] %> = buf.unpack('<%= f['unpack_type'] %><%= f['count'] %>')[0]
%    else # A variable-width thing, until null
    tmp = io.gets("\x00")
    unless tmp.nil?
      @<%= f['name'] %> = tmp.rstrip!
    end
%    end
%  end
% }
  end

  def dump()
    output = ""
% fmt['struct'].each { |f|
%   unless f['type'].nil?
%     if f['type'] == 'variable_to_null'
    output += @<%= f['name'] %> + "\\0"
%     else
    output += [@<%= f['name'] %>].pack('<%= f['type'] %>')
%     end
%   else
    output += [@<%= f['name'] %>].pack('<%= f['pack_type'] %><%= f['count'] %>')
%   end
% }    
    output
  end
end
_EOS_

  puts data
  out = ERB.new(data, nil, "%<").result(binding)
  out
end

x = make_dump_and_load("fuel_fmt.yaml")
puts x

eval x

# a = Thing.new()
# a.Foo = 15
# a.Bar = 255
# a.Blah = "Short string"
# a.Var = "A variable length string"
# a.pi = 3.14156926

# serial = a.dump
# serial = StringIO.new(serial)

# b = Thing.new()
# b.load(serial)

# puts b.Foo
# puts b.Bar
# puts b.Blah
# puts b.Var
# puts b.pi


