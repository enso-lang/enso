
require 'core/semantics/code/interpreter'
# TODO: error handling

module Paths
  def self.new(start = nil)
    Path.new(start)
  end

  class Path
    include Interpreter::Dispatcher
    
    def self.set_factory(factory)
      @@factory = factory
    end
    
    def initialize(path = @@factory.EVar("root"))
      @path = path
    end
    
    def field(name)
      @path = @@factory.EField(@path, name)
      self
    end
    
    def key(key)
      index(key)
    end

    def index(index)
      @path = @@factory.ESubscript(@path, @@factory.EStrConst(index))
      self
    end
        
    def deref?(scan, root = scan)
      begin
        deref(scan, root = scan)
      rescue
        false
      end
    end
    
    def to_s()
      to_s_path(@path)
    end
    
    def to_s_path(path)
      dispatch_obj(:to_s, path)
    end
    
    def to_s_EVar(obj)
      obj.name
    end

    def to_s_EConst(obj)
      obj.val
    end
        
    def to_s_EField(obj)
      "#{to_s_path(obj.e)}.#{obj.fname}"
    end

    def to_s_ESubscript(obj)
      "#{to_s_path(obj.e)}[#{to_s_path(obj.sub)}]"
    end

    def deref(root)
      dynamic_bind root: root do 
        eval
      end
    end
    
    def eval(path = @path)
      dispatch_obj(:eval, path)
    end
    
    def eval_EVar(obj)
      raise "undefined variable #{obj.name}" if !@D.include?(obj.name.to_sym)
      #puts("VAR #{obj.name} => #{@D[obj.name.to_sym]}")
      @D[obj.name.to_sym]
    end

    def eval_EConst(obj)
      obj.val
    end
        
    def eval_EField(obj)
      eval(obj.e)[obj.fname]
    end

    def eval_ESubscript(obj)
      eval(obj.e)[eval(obj.sub)]
    end

    def assign(root, obj)
      raise "Can only assign to lvalues not to #{self}" if not lvalue?
      owner.deref(root)[last.name] = obj
    end

    def assign_and_coerce(root, value)
      raise "Can only assign to lvalues not to #{self}" if not lvalue?
      obj = owner.deref(root)
      fld = obj.schema_class.fields[last.name]
      if fld.type.Primitive? then
        value = 
          case fld.type.name 
          when 'str' then value.to_s
          when 'int' then value.to_i
          when 'bool' then (value.to_s == 'true') ? true : false
          when 'real' then value.to_f
          else
            raise "Unknown primitive type: #{fld.type.name}"
          end
      end
      owner.deref(root)[last.name] = value
    end
  end
end

