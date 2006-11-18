#!/usr/bin/env ruby

require 'RubyPDB'
require 'lib/common.rb'

class ToDoRecord < RecordEntry
  def load
    date, priority = @buffer.unpack("nC")

    @data = {}
    @data['due_date'] = convert_from_palm_date(date)

    if (priority & 0x80)
      @data['completed'] = true
    else
      @data['completed'] = false
    end
    
    @data['priority'] = priority & 0x7f
    rest = @buffer[3, @buffer.length]

    @data['description'], @data['note'] = rest.split("\x00")
  end

  def dump
    palmdate = convert_to_palm_date(@data['due_date'])
    prio = @data['priority'] & 0x7f
    if @data['completed'] == true
      prio |= 0x80
    end

    newbuffer = [palmdate, prio].pack("n C")

    unless @data['description'].nil?
      newbuffer += @data['description'] + "\x0"
    else
      newbuffer += "\x0"
    end

    unless @data['note'].nil?
      newbuffer += @data['note'] + "\x0"
    else
      newbuffer += "\x0"
    end

    return newbuffer
  end
end

class ToDoDB < PalmPDB
  def initialize()
    super()
    @recordclass = ToDoRecord
  end
end

a = ToDoDB.new()
a.open_PDB_file("/home/socket/archives/palm/2005-10-16/ToDoDB.pdb")

a.records.each { |r|
  puts r.data.to_yaml
}

