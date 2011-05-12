
require 'core/system/library/cyclicmap'
require 'core/system/load/load'

class OldImplode < Dispatch

  def initialize(factory)
    @factory = factory
  end

  def self.implode(pt)
    OldImplode.new(Factory.new(Loader.load('instance.schema'))).recurse(pt, false)
  end

  def ParseTree(this, in_field)
    is = recurse(this.top, in_field)
    @factory.Instances(is.is_a?(Array) ? is : [is])
  end

  def Sequence(this, in_field)
    elts = this.elements.inject([]) do |cur, elt|
      sub = recurse(elt, false)
      if sub.is_a?(Array) then
        cur + sub
      else
        cur + [sub]
      end
    end
    elts.compact
  end
  
  def Create(this, in_field)
    [@factory.Instance(this.name, recurse(this.arg, false))]
  end

  def Field(this, in_field)
    x = recurse(this.arg, true)
    @factory.Field(this.name, x)
  end

  def Code(this, in_field)
    [@factory.Code(this.code)]
  end

  def Value(this, in_field)
    [@factory.Prim(this.kind, this.value)]
  end

  def Lit(this, in_field)
    if in_field then
      [@factory.Prim('str', this.value)]
    end
  end

  def Ref(this, in_field)
    [@factory.Ref(this.name)]
  end

end
