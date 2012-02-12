
module Dispatch1
  def method_missing(method_sym, *arguments, &block)
    obj = arguments[0]
    raise "Interpreter: obj is nil for method #{method_sym}" if obj.nil?
    #raise "Interpreter: invalid obj #{obj} for method #{method_sym}" if !obj.is_a? ManagedData::MObject
    args = arguments[1]
    raise "Interpreter: args is not a hash in #{obj}.#{method_sym}" if args and !args.is_a? Hash

    args ||= {}
    args[:self] = obj

    fields = Hash[obj.schema_class.all_fields.map{|f|[f.name,obj[f.name]]}]
    #puts "#{obj.class} fields['type']=#{fields['type']},#{obj.type}" if obj.schema_class.name == "Field"
    __call(method_sym, fields, obj.schema_class, args)

  end

  private

  def __call(method_sym, fields, type, args)
    #puts "Callin #{type}.#{method_sym} #{fields} #{args}"
    m = Lookup(type) {|o| m = "#{method_sym}_#{o.name}"; method(m.to_sym) if respond_to?(m) }
    if !m.nil?
      params = []
      m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}.each do |f|
        params << fields[f]
      end
      m.call(*params, args)

    elsif respond_to?("#{method_sym}_?")
      m = method("#{method_sym}_?".to_sym)
      m.call(fields, type, args)

    else
      raise "Interpreter: Unable to resolve method #{method_sym} for #{obj}"
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
