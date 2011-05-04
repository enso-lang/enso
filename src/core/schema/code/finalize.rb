class VisitFields < MemoBase
  def initialize(pass)
    super()
    @pass = pass
    @indent = 0
  end

  def finalize(obj)
    return if obj.nil? || @memo[obj]
    #puts " "*@indent + "#{@pass} #{obj}"
    @indent += 1    
    @memo[obj] = true
    obj.schema_class.fields.each do |f|
      Field(f, obj)
    end
    @indent -= 1
  end
  
  def Field(field, obj)
    return if field.computed
    val = obj[field.name]

    #puts " "*@indent + "CHECKING #{obj}.#{field.name}:'#{val}'"
    @indent += 1

    visitField(field, obj, val)
    if !(field.type.Primitive? || val.nil?)
      # check the field values    
      _each(field, val) do |val|
        finalize(val)
      end
    end
    @indent -= 1
  end  

  def _each(field, val)
    if !field.many
      yield val
    else
      val.each do |x|
        yield x
      end
    end
  end
end

class CheckRequired < VisitFields
  def visitField(field, obj, val)
    if !field.optional && (!field.many ? val.nil? : val.empty?)
      raise "Field '#{obj}.#{field.name}' is required" 
    end
  end
end


class UpdateInverses < VisitFields
  def visitField(field, obj, val)
    return if val.nil? || field.type.Primitive?
    # update delayed inverses
    if field.inverse && field.inverse.many
      #puts " "*@indent + "INVERTED #{obj}.#{field.inverse.name}"
      _each(field, val) do |val|
        if !val[field.inverse.name].include?(obj)
          #puts " "*@indent + "FIXING #{obj}.#{field.inverse.name}"
          val[field.inverse.name] << obj
        end
      end
    end
  end
end