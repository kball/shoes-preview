module ShoeShine
  def self.included(klass)
    klass.instance_eval do
      include HandlerChains
      include TrickleDown
    end
  end
  HANDLERS = [:click, :hover, :leave, :motion, :release]
  module HandlerChains
    def self.included(klass)
      klass.instance_eval do
        ShoeShine::HANDLERS.each do |handler|
          if klass.instance_methods.include? handler.to_s
            # Replace old handlers with new handlers
            alias_method "#{handler}_without_chains".to_sym, handler
            alias_method handler, "#{handler}_with_chains".to_sym
          end
        end
      end
    end
    HANDLERS.each do |handler|
      eval %(
        def #{handler}_with_chains(&block)
          #need to clear handlers to maintain old semantics
          clear_handlers(:#{handler})
          add_handler(:#{handler}, &block)
        end
      )
    end

    def clear_handlers(type)
      if @_handlers
        if @_handlers.delete(type)
          _handler_deleted(type)
        end
      end
    end

    def handler_deleted(&block)
      @handler_deleted_callbacks ||=[]
      @handler_deleted_callbacks.push block
    end

    def _handler_deleted(type)
      @handler_deleted_callbacks.each {|block| block.call(type)}
    end

    def add_handler(type, &block)
      @_handlers ||= {}
      @_handlers[type] ||= []
      @_handlers[type].push block
      # set up callbacks from old handlers invocation into
      # new handler chain
      self.send "#{type}_without_chains".to_sym do |*args|
        self.call_handlers(type, *args)
      end
    end

    def call_handlers(type, *args)
      return unless @_handlers[type]
      @_handlers[type].each do |block|
        block.call(*args)
      end
    end
  end

  # The idea of TrickleDown is to pass down events to the children of slots.
  # This is to work around the fact that paras etc don't seem to really get
  # hover etc events.  Unfortunately, this still doesn't solve it for hover,
  # because the hover event only gets triggered on mouseover of the main slot.
  # Really what I need to do if I'm going to do this is have a lookup table
  # and go into it on mouse movement.  HoverHack tries to do this.
  # 
  module TrickleDown
    TRICKLE_HANDLERS = [:click, :release]
    class Point
      def initialize(left, top)
        @left = left
        @top = top
      end
      # elem must respond to left, top, width, and height
      def inside?(elem)
        [:left, :top, :width, :height].each do |type|
          return false unless elem.respond_to? type
        end
        (@left > elem.left) && (@left < elem.left + elem.width) &&
        (@top > elem.top) && (@top < elem.top + elem.height)
      end
    end
    def self.included(klass)
      klass.instance_eval do
        # Replace old handlers with new handlers
        alias_method :call_handlers_without_passdown, :call_handlers
        alias_method :call_handlers, :call_handlers_with_passdown
      end
    end
    def call_handlers_with_passdown(type, *args) 
      call_handlers_without_passdown(type, *args)
      if TRICKLE_HANDLERS.include?(type)
        # TODO: Figure out how to do this with keypress dealing with focus
        b, l, t = self.app.mouse
        point = Point.new(l, t)
        me = self.respond_to?(:children) ? self : self.slot
        me.children.each do |child|
          if point.inside?(child) &&
             child.respond_to?(:call_handlers_with_passdown)
            child.call_handlers_with_passdown(type, *args)
          end
        end
      end      
    end
  end
end

Shoes.constants.each do |c|
  k = Shoes.const_get(c)
  if k.is_a? Class
    k.send :include, ShoeShine
  end
end
