
require 'core/semantics/code/interpreter'
require 'core/schema/tools/equals'
# TODO: error handling

module Paths
  def self.new(start = nil)
    Path.new(start)
  end

  class Path
    include Interpreter::Dispatcher
    
    attr_reader :path

    def self.set_factory(factory)
      @@factory = factory
    end

    def initialize(path = @@factory.EVar("root"))
      @path = path ? path : @@factory.EVar("root")
    end

    def field(name)
      Path.new(@@factory.EField(@path, name))
    end
    
    def key(key)
      Path.new(@@factory.ESubscript(@path, @@factory.EStrConst(key)))
    end

    def index(index)
      Path.new(@@factory.ESubscript(@path, @@factory.EIntConst(index)))
    end

    def equals(other)
      Equals::equals(@path, other.path)
    end

    def deref?(root)
      begin
        !deref(root).nil?
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

    def assign(root, val)
      obj = @path
      if obj.EField?
        dynamic_bind root: root do
          eval(obj.e)[obj.fname] = val
        end
      elsif obj.ESubscript?
        dynamic_bind root: root do 
          eval(obj.e)[eval(obj.sub)] = val
        end
      end
    end

    #insert is the same as assign, except that for arrays it injects into rather than replace
    def insert(root, val)
      obj = @path
      if obj.EField?
        dynamic_bind root: root do
          eval(obj.e)[obj.fname] = val
        end
      elsif obj.ESubscript?
        dynamic_bind root: root do 
          eval(obj.e).insert(eval(obj.sub), val)
        end
      end
    end
    def delete(root)
      obj = @path
      if obj.EField?
        dynamic_bind root: root do
          eval(obj.e)[obj.fname] = nil
        end
      elsif obj.ESubscript?
        dynamic_bind root: root do
          eval(obj.e).delete(eval(obj))
        end
      end
    end

    def type(root, obj = @path)
      if obj.EField?
        dynamic_bind root: root do
          eval(obj.e).schema_class.fields[obj.fname]
        end
      elsif obj.ESubscript?
        type(root, obj.e)
      end
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

