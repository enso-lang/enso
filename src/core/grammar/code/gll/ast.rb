
module AST
  def self.build(ast, fact)
    obj = ast.build(nil, nil, 0, fact, fixes = [])
    fixes.each do |fix|
      fix.apply(obj)
    end
    return obj
  end

  class Value
    attr_reader :origin
    def initialize(org)
      @origin = org
    end

    def update(owner, field, pos, x)
      return pos if field.nil?
      if field.many then
        owner[field.name] << x
        return pos + 1
      else
        owner[field.name] = x
      end
      return pos
    end

    def update_origin(owner, field, org)
      return if field.nil?

      # currently, no support for many fields:
      # since we allow lists of refs, the origin table
      # then would have to mimick the fixup process
      # (primitives are not allowed in many fields anyhow)
      return if field.many
      
      # _origin_of is a OpenStruct (it does not have [])
      # so we use send here. This seems ok, since this
      # is the only place where we will (?) need generic
      # access.
      owner._origin_of.send("#{field.name}=", org)
    end
  end

  class Instance < Value
    attr_reader :type, :contents
    def initialize(type, org)
      super(org)
      @type = type
      @contents = []
    end

    def build(owner, field, pos, factory, fixes)
      current = factory[type]
      contents.each do |cnt|
        cnt.build(current, nil, 0, factory, fixes)
      end
      current._origin = origin
      if owner then
        update(owner, field, pos, current)
        update_origin(owner, field, origin)
        return owner
      end
      return current
    end
  end

  class Field
    attr_reader :name, :values
    def initialize(name)
      @name = name
      @values = []
    end

    def build(owner, field, pos, factory, fixes)
      f = owner.schema_class.fields[name]
      values.each do |v|
        v.build(owner, f, 0, factory, fixes)
      end
    end
  end

  class Code
    attr_reader :code
    def initialize(code)
      @code = code
    end
    
    def build(owner, field, pos, factory, fixes)
      owner.instance_eval(code.gsub(/@/, "self."))
    end
  end

  class Prim < Value
    attr_reader :kind, :value
    def initialize(kind, value, org)
      super(org)
      @kind = kind
      @value = value
    end

    def build(owner, field, pos, factory, fixes)
      return unless field
      update(owner, field, pos, convert(field.type))
      update_origin(owner, field, origin)
    end

    private

    def convert(ftype)
      convert_typed(kind, ftype)
    end
    
    def convert_typed(type, ftype = nil)
      case type
      when "str" then value
      when "bool" then value == "true"
      when "int" then value.to_i
      when "real" then value.to_f
      when "sym" then value
      when "atom" then ftype.nil? ? value : convert_typed(ftype.name)
      else
        raise "Don't know kind #{type}"
      end
    end
  end

  class Ref < Value
    attr_reader :path
    def initialize(path, org)
      super(org)
      @path = path
    end

    def build(owner, field, pos, factory, fixes)
      fixes << Fix.new(path, owner, field, pos)
      if field.many && !ClassKey(field.type)
        update(owner, field, pos, nil)
      end
      update_origin(owner, field, origin)
    end
  end
  

  class Fix
    def initialize(path, this, field, pos)
      @path = path
      @this = this
      @field = field
      @pos = pos
    end

    def apply(root)
      # nil for parent; unsupported yet
      # (and static checking of parent paths is problematic)
      #puts "Dereffing: #{@path}"
      actual = @path.deref(root, @this)
      raise "Could not deref path: #{@path}" if actual.nil?
      if @field.many
        if ClassKey(@field.type)
          @this[@field.name] << actual
        else
          @this[@field.name][@pos] = actual
        end
      else
        @this[@field.name] = actual
      end
    end
  end

end
