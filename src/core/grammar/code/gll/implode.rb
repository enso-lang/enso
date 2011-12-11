
require 'core/schema/code/factory'

require 'core/grammar/code/gll/unparse'
require 'core/grammar/code/gll/ast'
require 'core/grammar/code/gll/to-path'
require 'core/system/load/load'
require 'core/system/utils/location'

class Implode
  include AST

  def self.implode(sppf, origins)
    Implode.new(origins).implode(sppf)
  end
  
  def initialize(origins)
    @origins = origins
  end


  def implode(sppf)
    insts = []
    recurse(sppf, insts, false)
    return insts.first
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
      Unparse.unparse(sppf, s = '')
      puts "\t #{s}"
      raise "Ambiguity!" 
    end
    
    return if sppf.kids.empty?
    pack = sppf.kids.first
    recurse(pack.left, accu, in_field) if pack.left
    recurse(pack.right, accu, in_field)
  end

  def Create(this, sppf, accu, in_field)
    inst = Instance.new(this.name, origin(sppf))
    kids(sppf, inst.contents, false)
    accu << inst
  end

  def Field(this, sppf, accu, in_field)
    fld = Field.new(this.name)
    kids(sppf, fld.values, true)
    accu << fld
  end

  def Lit(this, sppf, accu, in_field)
    return unless in_field
    accu << Prim.new('str', this.value, origin(sppf))
  end

  def Value(this, sppf, accu, in_field)
    accu << Prim.new(this.kind, sppf.value, origin(sppf))
  end

  def Ref2(this, sppf, accu, in_field)
    accu << Ref.new(ToPath.to_path(this.path, sppf.value), origin(sppf))
  end

  def Code(this, sppf, accu, in_field)
    accu << Code.new(sppf.value)
  end

  private
  
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

end
