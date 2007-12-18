#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), '..', 'lib', 'rubypdb', 'common.rb')

require 'test/unit'
require 'yaml'
require 'parsedate'

class TimeTest < Test::Unit::TestCase
  def test_time_class
    palm_time_number = 3201584529

    t = Time.local(*ParseDate.parsedate("2005-06-14 03:02:09 MDT"))
    pt = Time.from_palm(palm_time_number)

    assert (t == pt)
    assert (pt.to_palm == palm_time_number)
    assert (t.to_palm == pt.to_palm)
  end

  def test_date_class
    a = Date.new(2005, 6, 14)
    b = Date.from_palm(a.to_palm)
    assert a == b
  end
end