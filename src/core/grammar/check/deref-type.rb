
require 'set'

class DerefType

  # Dereference a path on a schema
  # resulting in a type.

  class AmbiguousParent < Exception
    attr_reader :candidates
    def initialize(candidates)
      @candidates = candidates
    end
  end

  def self.deref(schema, root_class, this_type, path)
    DerefType.new(schema, root_class, this_type).eval(path)
  end

  def initialize(schema, root_class, this_type)
    @schema = schema
    @root_class = root_class
    @this_type = this_type
  end

  def eval(this)
    send(this.schema_class.name, this)
  end

  def Anchor(this)
    if this.type == '.' then
      @this_type
    elsif this.type == '..' then
      candidates = Set.new
      @schema.classes.each do |c|
        c.fields.each do |f|
          if f.traversal && f.type == @this_type then
            candidates << c
          end
        end
      end
      if candidates.length > 1 then
        # TODO: should be error message
        raise AmbiguousParent.new(candidates)
      end
      candidates.first
    else
      raise "Invalid anchor: #{this.type}"
    end
  end

  def Sub(this)
    # Keys can be ignored here.
    ctx = this.parent ? eval(this.parent) : @root_class
    # make error if primitive
    # or invalid reference in general
    # how should we check that the class found
    # here is actuall also instantiated on the spine?!?!?!
    klass = subclass_for(ctx, this.name)
    if klass then
      klass.all_fields[this.name].type
    else
      nil
    end
  end

  def subclass_for(klass, fname)
    return nil if klass.nil?
    if klass.all_fields[fname] then
      return klass
    end
    klass.subclasses.each do |k|
      t = subclass_for(k, fname)
      return t if t
    end
    return nil
  end
      
end
