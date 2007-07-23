#!/usr/bin/env ruby


module A
  def set_foo(value)

    @foo = value
  end

  def get_foo()
    puts "Foo is: #{@foo}."
  end
end

class C
  include A
  extend A

  set_foo "Foo!"
end

c = C.new
c.get_foo()  # => "Foo is: ."
