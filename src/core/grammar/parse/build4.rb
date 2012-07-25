

require 'core/semantics/factories/combinators'

# Extend grammar objects so support instantiation
# in double dispatch with SPPF nodes.

# To get this really right
# - Add items to the grammar schema
# - make factory comply to class factories
# - make factory extension for immutability
# - implement factory extension that implements maximal sharing
# - make schema for SPPF which includes grammar
# - unparse = interpreter over SPPF
# - build = interpreter over SPPF
# - todot = interpreter over SPPF

class Build4
  include Factory

  def Grammar(sup)
    Class.new(sup) do
      attr_reader :start
      def build(sppf, fact, orgs)
        start.build(sppf, fact, orgs)
      end
    end
  end

  def Rule(sup)
    # Needed because Rule is not a pattern.
    Class.new(sup) do 
      attr_reader :arg
      def build(sppf, fact, orgs)
        arg.build(sppf, fact, orgs)
      end

      def build_spine(sppf, owner, accu, field, fixes, paths, fact, orgs)
        sppf.build_kids(owner, accu, field, fixes, paths, fact, orgs)
      end
    end
  end
      
  
  def Pattern(sup)
    Class.new(sup) do
      def build(sppf, fact, orgs)
        sppf.build(nil, accu = {}, nil, fixes = [], paths = {}, fact, orgs)
        obj = accu.values.first
        fixup(obj, fixes)
        return obj
      end

      def build_spine(sppf, owner, accu, field, fixes, paths, fact, orgs)
        sppf.build_kids(owner, accu, field, fixes, paths, fact, orgs)
      end

      private

      def fixup(root, fixes)
        begin
          later = []
          change = false
          fixes.each do |fix|
            if fix.apply(root) then
              change = true
            else # try it later
              later << fix
            end
          end
          fixes = later
        end while change
        raise "Fix-up error: unable to fixup #{later}" unless later.empty?
      end
    end
  end

  def Sequence(sup)
    Class.new(sup) do
      def build_spine(sppf, owner, accu, field, fixes, paths, fact, orgs)
        super(sppf, owner, accu, nil, fixes, paths, fact, orgs)
      end
    end
  end

  def Create(sup)
    Class.new(sup) do
      def build_spine(sppf, owner, accu, field, fixes, paths, fact, orgs)
        current = fact[name]
        super(sppf, current, {}, nil, fixes, {}, fact, orgs)
        current._origin = org = sppf.origin(orgs)
        accu[org] = current
      end
    end
  end


  def Field(sup)
    Class.new(sup) do
      def build_spine(sppf, owner, accu, _, fixes, paths, fact, orgs)
        field = owner.schema_class.fields[name]
        raise "Object #{owner} has no field #{name}" if !field
        super(sppf, owner, accu = {}, field, fixes, paths = {}, fact, orgs)
        accu.each do |org, value|
          # convert the value again, this time based on the field type
          # (if atom was used in the grammar this is needed)
          val = convert_value(value, field.type)
          if field.many then
            owner[field.name] << val
          else
            owner[field.name] = val
          end
          owner._set_origin_of(field.name, org)
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
  end

  def Code(sup)
    Class.new(sup) do
      def build_spine(sppf, owner, accu, field, fixes, paths, fact, orgs)
        expr.eval(ObjEnv.new(owner))
      end
    end
  end

  def Lit(sup)
    Class.new(sup) do
      def build_spine(sppf, owner, accu, field, fixes, paths, fact, orgs)
        return unless field
        accu[sppf.origin(orgs)] = value
      end
    end
  end

  def Ref(sup)
    Class.new(sup) do
      attr_reader :path
      def build_spine(sppf, owner, accu, field, fixes, paths, fact, orgs)
        paths[sppf.origin(orgs)] = path.resolve(sppf.value)
      end
    end
  end

  def Value(sup)
    Class.new(sup) do
      def build_spine(sppf, owner, accu, field, fixes, paths, fact, orgs)
        accu[sppf.origin(orgs)] = convert_token(sppf.value, kind)
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
  end

  class Fix
    attr_reader :path, :obj, :field, :origin

    def initialize(path, obj, field, origin)
      @path = path
      @obj = obj
      @field = field
      @origin = origin
    end

    def apply(root)
      x = path.deref(root, obj)
      if x then
        if field.many then
          obj[field.name] << x
        else
          obj[field.name] = x
        end
        obj._set_origin_of(field.name, origin)
        return true
      end
      return false
    end
  end


end
