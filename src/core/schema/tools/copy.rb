
# the important thing about copy is that it does NOT use
# the traversal fields (spine) of the structure.

class Copy
  def initialize(factory, memo = {})
    @factory = factory
    @memo = memo
  end

  def register(source, target)
      @memo[source] = target
  end
  
  def copy(source, *args)
    return nil if source.nil?
    target = @memo[source]
    return target if target
    #puts "COPY #{source} #{args}"
    klass = source.schema_class
    raise "Source does not have a schema_class #{source}" unless klass
    target = @factory[klass.name]

    klass.fields.each do |field|
      next if field.computed
      if field.type.Primitive?
        target[field.name] = source[field.name]
      end
    end

    register(source, target)

    klass.fields.each do |field|
      next if field.computed || field.type.Primitive? || (field.inverse && field.inverse.traversal)
      #puts "  FIELD #{field.name} #{source[field.name].class} #{source[field.name]}"
      if !field.many
        target[field.name] = copy(source[field.name], *args)
      else
        source[field.name].each do |x|
          target[field.name] << copy(x, *args)
        end
      end
    end
    return target
  end
end


if __FILE__ == $0 then

  require 'core/system/load/load'
  
  gs = Loader.load('grammar.schema')
  sg = Loader.load('schema.grammar')

  require 'core/schema/tools/print'
  
  newSchema = Copy.new(Factory.new(gs)).copy(sg)
  newSchema.finalize()
  
  Print.print(newSchema)
end
