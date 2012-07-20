
require 'core/grammar/parse/unparse'
require 'core/grammar/parse/to-path'
require 'core/grammar/tools/todot'
require 'core/system/utils/location'
require 'core/expr/code/assertexpr'

module BuildEval
  class Grammar
    def build(sppf, factory, origins)
      # TODO: have to pass factory and origins through
      sppf.type.build(sppf, nil, accu = {}, nil, fixes = [], paths = {})
      obj = accu.values.first
      fixup(obj, fixes)
      return obj
    end

    def fixup(root, fixes)
      begin
        later = []
        change = false
        fixes.each do |fix|
          x = fix.path.deref(root, fix.obj)
          if x then # the path can resolved
            update(fix.obj, fix.field, x)
            update_origin(fix.obj, fix.field, fix.origin)
            change = true
          else # try it later
            later << fix
          end
        end
        fixes = later
      end while change
      raise "Fix-up error: unable to fixup #{later}" unless later.empty?
    end

    def update(owner, field, x)
      #puts "Updating: #{owner}.#{field.name} := #{x}"
      if field.many then
        owner[field.name] << x
      else
        owner[field.name] = x
      end
    end
    
    def update_origin(owner, field, org)
      #return if field.many # no origins for collections
      
      # _origin_of is a OpenStruct (it does not have [])
      # so we use send here. This seems ok, since this
      # is the only place where we will (?) need generic
      # access.
      #owner._origin_of.send("#{field.name}=", org)
      #owner.__get(field.name)._origin = org
      owner._set_origin_of(field.name, org)
    end

  end


  class Pattern # never to be instantiated
    def build(sppf, owner, accu, field, fixes, paths)
      kids(sppf, owner, accu, nil, fixes, paths)
    end

    def origin(sppf)
      path = @origins.path
      offset = @origins.offset(sppf.starts)
      length = sppf.ends - sppf.starts
      start_line = @origins.line(sppf.starts)
      start_column = @origins.column(sppf.starts)
      end_line = @origins.line(sppf.ends)
      end_column = @origins.column(sppf.ends)
      Location.new(path, offset, length, start_line, 
                   start_column, end_line, end_column)
    end

    def kids(sppf, owner, accu, field, fixes, paths)
      amb_error(sppf) if sppf.kids.length > 1
      return if sppf.kids.empty?
      pack = sppf.kids.first
      pack.left.build(pack.left, owner, accu, field, fixes, paths) if pack.left
      pack.right.build(pack.right, owner, accu, field, fixes, paths)
    end
    
    def amb_error(sppf)
      Unparse.unparse(sppf, s = '')
      #File.open('amb.dot', 'w') do |f|
      #  ToDot.to_dot(sppf, f)
      #end
      raise "Ambiguity: >>>#{s}<<<" 
    end



  end


  class Create < Pattern
    attr_reader :name

    def build(sppf, owner, accu, field, fixes, paths)
      current = @factory[name]
      #puts "Creating: #{name}"
      kids(sppf, current, {}, nil, fixes, {})
      current._origin = org = origin(sppf)
      accu[org] = current
    end
  end




  class Field < Pattern
    attr_reader :name

    def build(sppf, owner, accu, _, fixes, paths)
      field = owner.schema_class.fields[name]
      #puts "FIELD: #{name}"
      # TODO: this check should be done if owner = Env
      # for new paths.
      raise "Object #{owner} has no field #{name} as required by grammar fixups" if !field
      kids(sppf, owner, accu = {}, field, fixes, paths = {})
      accu.each do |org, value|
        # convert the value again, this time based on the field type
        # (if atom was used in the grammar this is needed)
        update(owner, field, convert_value(value, field.type))
        update_origin(owner, field, org)
      end
      paths.each do |org, path|
        fixes << Fix.new(path, owner, field, org)
      end
    end

    def convert_value(value, type)
      return value unless type.Primitive?
      case type.name
      when "str" then value
      when "bool" then value == "true"
      when "int" then value.to_i
      when "real" then value.to_f
      when "atom" then value # possibly already converted based on token kind
      else
        raise "Don't know primitive type #{type.name}"
      end
    end
  end

  class Lit < Pattern
    def build(sppf, owner, accu, field, fixes, paths)
      return unless field
      accu[origin(sppf)] = sppf.value
    end
  end

  class Value < Pattern
    attr_reader :kind

    def build(sppf, owner, accu, field, fixes, paths)
      accu[origin(sppf)] = convert_token(sppf.value, kind)
    end

    
    def convert_token(value, kind)
      case kind 
      when "str" then value
      when "int" then value.to_i
      when "real" then value.to_f
      when "sym" then value
      when "atom" then value # ???
      else
        raise "Don't know kind #{kind}"
      end
    end
  end

  class Ref < Pattern
    attr_reader :path
    def build(sppf, owner, accu, field, fixes, paths)
      paths[origin(sppf)] = ToPath.to_path(path, sppf.value)
    end
  end

  class Code < Pattern
    attr_reader :expr
    def build(sppf, owner, accu, field, fixes, paths)
      #Interpreter(AssertExpr).assert(expr, env: ObjEnv.new(owner))
      expr.eval(ObjEnv.new(owner))
    end
  end

 


  class Fix
    attr_reader :path, :obj, :field, :origin
    def initialize(path, obj, field, origin)
      @path = path
      @obj = obj
      @field = field
      @origin = origin
    end    
  end
end
