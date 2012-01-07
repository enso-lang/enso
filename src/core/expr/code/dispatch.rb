
module Dispatch1

  def method_missing(method_sym, obj, arguments=nil, &block)
      if respond_to?("#{method_sym}_#{obj.schema_class.name}")
        m = method("#{method_sym}_#{obj.schema_class.name}".to_sym)
        fields = m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}

        params = []
        fields.each do |f|
          params << obj[f]
        end

        m.call(*params, arguments)
      #elsif !obj.schema_class.supers.empty?
        #do superclass lookup
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
  extend Dispatch1
  def method_missing(method_sym, obj, arguments=nil, &block)
    @memo={} if @memo.nil?
    @memo[obj] if @memo[obj]
    @memo=obj
    @memo=super(method_sym, obj, arguments.merge({:obj=>obj}), &block)
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
