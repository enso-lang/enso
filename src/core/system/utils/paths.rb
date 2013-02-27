
require 'core/schema/code/factory'
require 'core/system/load/load'
require 'core/semantics/code/interpreter'
# TODO: error handling

module Paths
  def self.parse(str)
    self.new.parse(str)
  end

  def self.new(start = nil)
    Path.new(start)
  end

  class Path
    include Interpreter::Dispatcher
    
    def initialize(path)
      @factory = Factory.new(Load::load('schema.schema'))
      @path = path || @factory.EVar("root")
    end

    def parse(str)
      str = str.gsub("\\", "")
      str.split(".").each do |part|
        if (n = part.index("[")) && part.slice(-1) == "]"
          field(part.slice(0, n))
          index(part.slice(n+1, part.length - n - 2))
        elsif part != ""
          field(part)
        end
      end
      #puts "PATH '#{str}' #{@path}"
      self
    end
    
    def field(name)
      @path = @factory.EField(@path, name)
      self
    end
    
    def key(key)
      index(key)
    end

    def index(index)
      @path = @factory.ESubscript(@path, @factory.EStrConst(index))
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
      #puts "Dereffing 'this': obj = #{obj}; root = #{root}"
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

