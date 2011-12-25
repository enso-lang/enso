
module InternalVisitorMod
  def self.init(action)
    @_action = action
  end
=begin
    res = self.clone
    mod.instance_methods(false).each do |m_name|
      next unless m_name.to_s.index("_")
      puts "Augmenting #{m_name}"
      action, type = m_name.to_s.split("_")
      puts "action = #{action}, type=#{type}"
      if type=="?"
        #this would be a good time to panic :(
      else
        m = mod.instance_method(m_name.to_sym)
        fields = m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}
        res.module_eval %{
          define_method(m_name) do |*arguments|
            if arguments.length > fields.length
              args = arguments[-1]
              arguments = arguments[0..-2]
            end

            params = []
            arguments.each do |f|
              #FIXME: this is absolutely 100% NOT the way to do things
              if f.is_a? BaseManyField
                l = obj[f.name].class.new
                self[f.name].each do |v|
                  l << send("#{action}", args)
                    send(method_sym, f, args)
                end
                params << l
              elsif f.is_a? CheckedObject
                params << send("#{action}", f, args)
              else
                params << f
              end
            end
            puts "Calling #{m_name}.super with params #{params}"
            super(*params, args)
          end
        }
      end
    end
    res.module_eval { include(mod) }
  end
=end
  def visit_?(fields, args=nil)
    type = args[:type]
    h = Hash[*type.fields.keys.zip(fields)]
    m = method("#{@_action}_#{type.name}")
    params = []
    m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}.each do |param|
      f = type.fields[param.to_s]
      val = h[param.to_s]
      if f.type.Primitive?
        params << val
      elsif !f.many
        params << visit(val, args)
      else
        l = val.class.new
        val.each do |v|
          l << visit(v, args)
        end
        params << l
      end
    end
    send(@_action, params, args)
  end
  def visit(obj, args={})
    super(obj, args.merge(:type=>obj.schema_class))  #effectively a call to method_missing
  end
end

def InternalVisitor(*args)
  InternalVisitorMod.init(*args)
end
