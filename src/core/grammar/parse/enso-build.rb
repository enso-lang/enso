
require 'core/grammar/parse/unparse'
require 'core/grammar/tools/todot'
require 'core/system/utils/location'
require 'core/expr/code/assertexpr'

module EnsoBuild

  def self.build(sppf, factory, origins, imports=[])
    Builder.new(factory, origins).build(sppf, imports)
  end

  class Builder

    def initialize(factory, origins)
      @factory = factory
      @origins = origins
    end

    def build(sppf, imports)
      build_sppf(sppf, nil, accu = {}, nil, fixes = [], paths = {})
      obj = accu.values.first
      imports.each do |import|
        obj._graph_id.unsafe_mode {
          obj = Union::CopyInto(obj.factory, import, obj)
        }
      end
      fixup(obj, fixes)
      return obj
    end

    ### 
    ### SPPF 
    ###

    def build_sppf(sppf, owner, accu, field, fixes, paths)
      send("build_sppf_#{sppf.schema_class.name}", sppf, owner, accu, field, fixes, paths)
    end

    def build_sppf_Node(sppf, owner, accu, field, fixes, paths)
      amb_error(sppf) if is_amb?(sppf)
      build_symbol(sppf.type, sppf, owner, accu, field, fixes, paths)
    end

    def build_sppf_Leaf(sppf, owner, accu, field, fixes, paths)
      build_symbol_leaf(sppf.type, sppf, owner, accu, field, fixes, paths)
    end

    def build_sppf_Pack(sppf, owner, accu, field, fixes, paths)
      build_sppf(sppf.left, owner, accu, field, fixes, paths) if sppf.left
      build_sppf(sppf.right, owner, accu, sppf.left ? nil : field, fixes, paths) 
    end


    ###
    ### GRAMMAR SYMBOLS
    ###

    def build_symbol_leaf(this, sppf, owner, accu, field, fixes, paths)
      puts "LEAF: #{this}"
      meth = "build_symbol_leaf_#{this.schema_class.name}"
      if respond_to?(meth)
        send(meth, this, sppf, owner, accu, field, fixes, paths)
      end
    end


    def build_symbol(this, sppf, owner, accu, field, fixes, paths)
      meth = "build_symbol_#{this.schema_class.name}"
      puts "trying #{this.schema_class.name} for #{sppf}"
      if respond_to?(meth)
        puts "building symbol #{this.schema_class.name}"
        send(meth, this, sppf, owner, accu, field, fixes, paths)
      else
        puts "recursing to kids"
        build_sppf(sppf.kids[0], owner, accu, field, fixes, paths)
      end
    end

    def build_symbol_Rule(this, sppf, owner, accu, field, fixes, paths)
      if this.original then
        build_symbol(this.original, sppf, owner, accu, field, fixes, paths)
      else
        build_sppf(sppf.kids[0], owner, accu, field, fixes, paths)
      end
    end

    def build_symbol_Create(this, sppf, owner, accu, field, fixes, paths)
      current = @factory[this.name]
      build_sppf(sppf.kids[0], current, {}, nil, fixes, {})
      current._origin = org = origin(sppf)
      accu[org] = current
    end

    def build_symbol_Field(this, sppf, owner, accu, _, fixes, paths)
      puts "FIELD: #{this.name}"
      field = owner.schema_class.fields[this.name]
      # TODO: this check should be done if owner = Env
      # for new paths.
      raise "Object #{owner} has no field #{this.name} as required by grammar fixups" if !field
      build_sppf(sppf.kids[0], owner, accu = {}, field, fixes, paths = {})
      accu.each do |org, value|
        # convert the value again, this time based on the field type
        # (if atom was used in the grammar this is needed)
        update(owner, field, convert_value(value, field.type))
        update_origin(owner, field, org)
      end
      paths.each do |org, fix|
        fix.obj = owner
        fix.field = field
        fixes << fix
      end
    end

    
    def build_symbol_leaf_Lit(this, sppf, owner, accu, field, fixes, paths)
      return unless field
      accu[origin(sppf)] = sppf.value
    end

    def build_symbol_leaf_Value(this, sppf, owner, accu, field, fixes, paths)
      accu[origin(sppf)] = convert_token(sppf.value, this.kind)
    end

    def build_symbol_leaf_Ref(this, sppf, owner, accu, field, fixes, paths)
      paths[origin(sppf)] = Fix.new(this.path, owner, field, origin(sppf), sppf.value)
    end

    def build_symbol_leaf_Code(this, sppf, owner, accu, field, fixes, paths)
      check = AssertExprC.new
      check.dynamic_bind env: Env::ObjEnv.new(owner) do
        check.assert(this.expr)
      end
    end


    private

    def is_amb?(sppf)
      sppf.kids.size > 1
    end

    def amb_error(sppf)
      Unparse.unparse(sppf, s = '')
      File.open('amb.dot', 'w') do |f|
        ToDot.to_dot(sppf, f)
      end
      raise "Ambiguity: >>>#{s}<<<" 
      
    end
    
    def origin(sppf)
      path = @origins.path
      offset = @origins.offset(sppf.starts)
      size = sppf.ends - sppf.starts
      start_line = @origins.line(sppf.starts)
      start_column = @origins.column(sppf.starts)
      end_line = @origins.line(sppf.ends)
      end_column = @origins.column(sppf.ends)
      Location.new(path, offset, size, start_line, 
                   start_column, end_line, end_column)
    end

    def convert_token(value, kind)
      case kind 
      when "str" then value
      when "int" then value.to_i
      when "real" then value.to_f
      when "sym" then value
      when "atom" then 
        if value =~ /[+-]?[0-9]+/
          value.to_i
        elsif value =~ /\A[+-]?\d+?(\.\d+)?\Z/
          value.to_f 
        else
          value
        end
      else
        raise "Don't know kind #{kind}"
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



    def fixup(root, fixes)
      begin
        later = []
        change = false
        fixes.each do |fix|
          helper = Paths::new(fix.path)
          x = helper.dynamic_bind root: root, this: fix.obj, it: fix.it do
            helper.eval
          end
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
      puts "Updating: #{owner}.#{field.name} := #{x}"
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

    class Fix
      attr_accessor :path, :obj, :field, :origin, :it
      def initialize(path, obj, field, origin, it)
        @path = path
        @obj = obj
        @field = field
        @origin = origin
        @it = it
      end
      def inspect
        "#{obj}.#{field} = #{path}"
      end     
    end
  end

end
