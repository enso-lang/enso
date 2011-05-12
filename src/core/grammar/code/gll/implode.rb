
require 'core/system/library/cyclicmap'

require 'core/system/boot/instance_schema'
require 'core/schema/code/factory'

class Implode

  def self.implode(sppf)
    Implode.new.implode(sppf)
  end
  
  def initialize
    @if = Factory.new(InstanceSchema.schema)
  end

  def implode(sppf)
    insts = @if.Instances
    Implode.new.recurse(sppf, insts.instances, false)
    return insts
  end
  

  def recurse(sppf, accu, in_field)
    type = sppf.type 
    sym = type.schema_class.name
    if respond_to?(sym)
      send(sym, type, sppf, accu, in_field)
    else
      kids(sppf, accu, false)
    end
  end

  def kids(sppf, accu, in_field)
    if sppf.kids.length > 1 then
      sppf.kids.each_with_index do |k, i|
        puts "Alt #{i}: #{k}"
        puts "\t #{k.left}"
        puts "\t #{k.right}"        
      end
      raise "Ambiguity!" 
    end
    
    return if sppf.kids.empty?
    pack = sppf.kids.first
    recurse(pack.left, accu, in_field) if pack.left
    recurse(pack.right, accu, in_field) #if pack.right
  end

  def Create(this, sppf, accu, in_field)
    #puts "Creating: #{this.name}"
    inst = @if.Instance(this.name)
    kids(sppf, inst.contents, false)
    accu << inst
  end

  def Field(this, sppf, accu, in_field)
    fld = @if.Field(this.name)
    kids(sppf, fld.values, true)
    accu << fld
  end

  def Lit(this, sppf, accu, in_field)
    return unless in_field
    accu << @if.Prim('str', this.value)
  end

  def Value(this, sppf, accu, in_field)
    accu << @if.Prim(this.kind, sppf.value)
  end

  def Ref(this, sppf, accu, in_field)
    accu << @if.Ref(sppf.value)
  end

  def Code(this, sppf, accu, in_field)
    accu << @if.Code(sppf.value)
  end

end
