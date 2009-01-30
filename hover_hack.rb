require 'shoe_shine'
require 'shoe_query'
# The goal of HoverHack is to work around the lack of hover/leave handlers on
# anything below the level of a slot.  It depends on ShoeShine being present to
# allow multiple event handlers.  It may also be very resource intensive... it
# puts together a 2 dimensional lookup table to be able to map any coordinate to
# the elements at that coordinate, and whenever there is mouse movement checks to
# see if there are changes.
#
# It also depends on shoe_query for the setup.
module HoverHack
  class LookupTable
    attr_accessor :lookup, :divisions, :height, :width
    def initialize(app_slot, divisions = 10)
      self.height = app_slot.height
      self.width = app_slot.width
      # set up 2-d lookup array
      self.divisions = divisions
      # this somewhat awkward array construction is to make sure each
      # lookup location is a unique array.  
      self.lookup = Array.new
      10.times do 
        inner = Array.new
        10.times { inner.push Array.new }
        lookup.push inner
      end
      app_slot.children.each do |child|
        self.add_lookups(child)
      end
    end
    def x_step
      width / divisions
    end
    def y_step
      height / divisions
    end

    def find_elems(x, y)
      point = ShoeShine::TrickleDown::Point.new(x, y)
      elems = self.lookup[x / x_step][y / y_step]
      elems.select do |elem|
        point.inside? elem
      end
    rescue
      []
    end
  
    def add_lookups(elem)
      return unless elem.respond_to?(:top)
      x1 = elem.top
      x2 = elem.top + elem.width
      y1 = elem.left
      y2 = elem.left + elem.width
      #there's got to be a more ruby-esque way of doing this
      x = x1; y = y1;
      while(x < x2)
        break unless lookup[x / x_step]
        while(y < y2)
          break unless lookup[x / x_step][y / y_step]
          lookup[x / x_step][y / y_step].push elem
          y += y_step
        end
        y = y1
        x += x_step
      end
      
      elem.children.each do |child|
        self.add_lookups(child)
      end
    end
  end

  def hover_hack_lookup_table
    lookup = self.app.instance_variable_get("@_hover_hack_lookup_table")
    unless lookup
      lookup = LookupTable.new(self.app.slot)
      self.app.instance_variable_set("@_hover_hack_lookup_table", lookup)
    end
    @_hover_hack_lookup_table = lookup
  end

  def hover_hack_current_list
    @_hover_hack_current_list ||= []
  end

  def hover_hack_handle_leaving(x, y)
    point = ShoeShine::TrickleDown::Point.new(x, y)
    leaving = hover_hack_current_list.select do |elem|
      !point.inside?(elem)
    end
    leaving.each do |elem|
      elem.call_handlers(:leave, elem)
      hover_hack_current_list.delete elem
    end
  end
  
  def hover_hack_handle_hover(x, y)
    elems = hover_hack_lookup_table.find_elems(x,y)
    if elems.size != hover_hack_current_list.size
      diff = elems - hover_hack_current_list
      diff.each do |elem|
        elem.call_handlers(:hover, elem)
        hover_hack_current_list.push elem
      end
    end
  end
  def hover_hack_handle_motion(x, y)
    return unless hover_hack_lookup_table
    hover_hack_handle_leaving(x, y)
    hover_hack_handle_hover(x, y)
  end

end

module HoverHackApp
  # an app method for initializing this whole mess.  There really should
  # be some sort of on_create handler that does this... hmm...
  def setup_hover_hack
    ['flow', 'stack'].each do |type|
      shoe_query(type).each do |elem|
        elem.add_handler(:motion) {|x, y| elem.hover_hack_handle_motion(x, y)} 
      end
    end
  end
end
[Shoes::Flow, Shoes::Stack].each do |klass|
  klass.send :include, HoverHack
end
Shoes::App.send :include, HoverHackApp
