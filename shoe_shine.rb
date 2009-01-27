module ShoeShine
  HANDLERS = [:click]
  def self.included(klass)
    klass.instance_eval do
      HANDLERS.each do |handler|
        if klass.instance_methods.include? handler.to_s
          # Replace old handlers with new handlers
          alias_method "#{handler}_old".to_sym, handler
          alias_method handler, "#{handler}_new".to_sym
        end
      end
    end
  end
  HANDLERS.each do |handler|
    eval %(
      def #{handler}_new(&block)
        add_handler(:#{handler}, &block)
      end
    )
  end
  def add_handler(type, &block)
    @_handlers ||= {}
    @_handlers[type] ||= []
    @_handlers[type].push block
    # set up callbacks from old handlers invocation into
    # new handler chain
    self.send "#{type}_old".to_sym do |*args|
      self.call_handlers(type, *args)
    end
  end

  def call_handlers(type, *args)
    @_handlers[type].each do |block|
      block.call(*args)
    end
  end
end
Shoes.constants.each do |c|
  k = Shoes.const_get(c)
  if k.is_a? Class
    k.send :include, ShoeShine
  end
end
