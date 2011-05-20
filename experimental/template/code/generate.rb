


class Generate
  def initialize(factory)
    @factory = factory
    @labels = {}
  end
  
  def generate(template, data)
    if template.Expression?
      return evaluate(template, data)
    elsif template.Ref?
      label = evaluate(template.label, data)
      return @labels[label] || (@labels[label] = @factory._placeholder)
    elsif template.GenericSeq?
      result = []
      template.items.each do |item|
        for_each generate(item, data) do |x|
          result << x
        end
      end
      return result
    elsif template.GenericAlt?
      template.alts.each do |alt|
        catch :fail do
          return generate(alt, data)
        end
      end
      throw :fail
    elsif template.GenericCond?
      throw :fail unless evaluate(template.condition, data)
      return generate(template.body, data)
    elsif template.GenericField?
      sub = data[template.name]
      raise "Unknown field '#{template.name}' on #{data}" unless sub
      return generate(template.body, sub)
    elsif template.GenericLabel?
      label = evaluate(template.label, data)
      val = @labels[label]
      result = generate(template.body, data)
      if val then
        val._become_ result
      else
        @labels[label] = result
      end
      return result
    else
      copy(template, data)
    end
  end    

  def for_each(part)
    if part.is_a?(Array)
      part.each do |x|
        yield x
      end
    else
      yield part
    end
  end

  def evaluate(exp, data)
    if exp.DotExpression?
      exp.items.each do |field|
        data = data[field.name]
      end
      return data
    elsif exp.AddExpression?
      result = ""
      exp.args.each do |sub|
        result = "#{result}#{evaluate(sub, data)}"
      end
      return result
    elsif exp.LiteralExpression?
      return exp.value
    end
  end

  def copy(template, data)
    tklass = template.schema_class
    target = @factory[tklass.name]
    tklass.fields.each do |tfield|
      next if tfield.many
      field = target.schema_class.fields[tfield.name]
      sub = template[tfield.name]
      next if sub.nil?
      val = generate(sub, data)
      if field.type.Primitive?
        target[field.name] = val
      elsif !field.many
        #if val.is_a?(CheckedObject)
        #  val = @factory._placeholder(val)
        #end
        raise "Multiple template values #{val} for single-valued field '#{field.name}'" if val.is_a?(Array) && val.length > 1
        for_each val do |x|
          target[field.name] = x
        end
      else
        for_each val do |x|
          target[field.name] << x
        end
      end
    end
    return target  
  end
  
end

