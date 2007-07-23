#!/usr/bin/env ruby
#
# This is a wishlist format, moving towards a domain-specific language.

class FuelLog
  include PalmDB

  # This should create self.fuel_dec, .price_dec, and .odom_dec
  # Along with read_appinfo, write_appinfo.
  # There will be a @categories[] list, containing the category names
  app_info_data do ||
    app_info_has_categories
    field :fuel_dec, :short
    field :price_dec, :short
    field :odom_dec, :short 
  end

  # This should mak a FuelLogRecord class.
  # In addition to importing the standard .delete? .dirty? .busy? .secret? flags,
  #    the category link (a string or symbol of the category name), and .uid numbers
  #    There will be .odometer= and .odometer, for setting/getting odometer.
  #    .from_palm_odometer converts to a number, .to_palm_odometer converts to a binary string
  # The flags field, identified by the block, makes a FuelLogRecordFlags class that has
  # a similar system: .a= and .a, .from_palm_a, .to_palm_a, etc.
  #
  # So, the field method basically takes the following parameters:
  #   name, type/length, &method
  #
  # The terminated_by method reads up until the terminator, and stores the contents into
  # a string.
  record_fields do
    field :odometer, :N
    field :gallons, :N
    field :date, :palm_date
    field :total_price, :short
    field :flags, :short, do
      field :a, :bit, 1
      field :b, :bit, 2
      # ...
    end
    field :notes, :terminated_by, 0x0
  end

  # Conversion routines.
  # A built-in one should check for anything with :palm_date type
  # and make from_palm_date and to_palm_date convert appropriately.
  # 
  def from_palm_gallons { |palm_gallons|
    palm_gallons.to_i / (10.0 ** self.fuel_dec)
  }
  def to_palm_gallons {|gallons|
    gallons ** (10.0 ** self.fuel_dec)
  }

  def from_palm_price {|palm_price|
    palm_price.to_i / (10.0 ** self.price_dec)
  }
  def to_palm_price {|price|
    price ** (10.0 ** self.price_dec)
  }

end
