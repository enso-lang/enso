
class Copy
  def initialize(factory)
    @factory = factory
    @memo = {}
  end

  def copy(source, *args)
    build(source, *args)
    result = link(source, true, *args)
    result.finalize
    return result
  end
  
  def build(source, *args)
    return nil if source.nil?
    klass = source.schema_class
    @memo[source] = target = @factory[klass.name]
    klass.fields.each do |field|
      #puts "Copying #{field.name} #{source[field.name].class} #{source[field.name]}"
      if field.type.Primitive?
        target[field.name] = source[field.name]
      elsif field.traversal
        if !field.many
          build(source[field.name], *args)
        else
          source[field.name].each do |x|
            build(x, *args)
          end
        end
      end
    end
  end

  def link(source, traversal, *args)
    return nil if source.nil?
    target = @memo[source]
    return target if !traversal
    target.schema_class.fields.each do |field|
      next if field.type.Primitive?
      #puts "Copying #{field.name} #{source[field.name].class} #{source[field.name]}"
      if !field.many
        target[field.name] = link(source[field.name], field.traversal, *args)
      else
        source[field.name].each do |x|
          target[field.name] << link(x, field.traversal, *args)
        end
      end
    end
    return target
  end
end


if __FILE__ == $0 then

  require 'core/system/load/load'
  
  ss = Loader.load('schema.schema')

  require 'core/schema/tools/print'
  require 'core/schema/code/factory'
  
  newSchema = Copy.new(Factory.new(ss)).copy(ss)
  newSchema.finalize()
  
  Print.print(newSchema)
  
  puts "#{newSchema.classes.class}"
  puts "WOA: #{newSchema.classes['Klass'].schema}"

end
