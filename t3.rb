#!/usr/bin/env ruby
#
# This is a wishlist format, moving towards a domain-specific language.

class FuelLog < PalmPDB
  app_info_data {
    field :fuel_dec, :short
    field :price_dec, :short
    field :odom_dec, :short 
  }

  app_info_has_categories  # Normal categories are used in the app_info record.

  record_fields {
    field :odometer, :N
    field :gallons, :N
    field :date, :palm_date
    field :total_price, :short
    field :flags, :short, {
      field :a, :bit, 1
      field :b, :bit, 2
      # ...
    }
    field :notes, :null_terminated_string
  }

  # Conversion routines.
  # A built-in one should check for anything with :palm_date type
  # and make from_palm_date and to_palm_date convert appropriately.
  # 
  def from_palm_gallons { |palm_gallons|
    palm_gallons.to_i / (10.0 ** @app_info.fuel_dec)
  }
  def to_palm_gallons {|gallons|
    gallons ** (10.0 ** @app_info.fuel_dec)
  }
  def from_palm_price {|palm_price|
    palm_price.to_i / (10.0 ** @app_info.price_dec)
  }
  def to_palm_price {|price|
    price ** (10.0 ** @app_info.price_dec)
  }
end
