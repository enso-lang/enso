
module Dispatch1
  def method_missing(method_sym, obj, arguments=nil, &block)
    m = Lookup(obj.schema_class) {|o| method("#{method_sym}_#{o.name}".to_sym) if respond_to?("#{method_sym}_#{o.name}") }
    if !m.nil?
      fields = m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}

      params = []
      fields.each do |f|
        params << obj[f]
      end

      m.call(*params, arguments)
    elsif respond_to?("#{method_sym}_?")
      m = method("#{method_sym}_?".to_sym)
      fields = obj.schema_class.all_fields

      params = {}
      fields.each do |f|
        params[f.name] = obj[f.name]
      end

      m.call(params, obj.schema_class, arguments)
    else
      nil
    end
  end
end

module WorkList
  include Dispatch1

  def initialize(initial=nil)
    @worklist = []
    @worklist = @worklist + initial unless initial.nil?
  end

  def method_missing(method_sym, obj=nil, arguments=nil, &block)
    @worklist << obj unless obj.nil? or @worklist.include?(obj)
    if !@working
      @working = true
      while !@worklist.empty?
        super(method_sym, @worklist.pop, arguments, &block)
      end
      @working = false
    end
  end
end

module Map
  include Dispatch1
  def method_missing(method_sym, obj, arguments={}, &block)
    @memo={} if @memo.nil?
    return @memo[obj] if @memo[obj]
    @memo[obj] = obj
    @memo[obj] = super(method_sym, obj, arguments.merge({:obj=>obj}), &block)
    obj.schema_class.fields.each do |f|
      if !f.type.Primitive?
        if !f.many
          send(method_sym, obj[f.name], arguments, &block) unless obj[f.name].nil?
        else
          obj[f.name].map{|o|send(method_sym, o, arguments, &block)}
        end
      end
    end
    @memo[obj]
  end
end

def map(obj, memo=[])
  memo[obj] = yield(obj) unless memo[obj]
  obj.schema_class.fields.each do |f|
    if !f.Primitive?
      if !f.many
        map(obj[f.name])
      else
        obj[f.name].map{|o|map(o)}
      end
    end
  end
  memo[obj]
end
