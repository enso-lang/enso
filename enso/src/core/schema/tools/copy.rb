
# class Copy2 < CyclicMap

#   def initialize(factory)
#     super()
#     @factory = factory
#   end

#   def run(schema, obj)
#     recurse(schema[obj.schema_class.name], obj, @factory[obj.schema_class.name])
#   end

#   def Klass(this, src)
#     register(@factory[this.name]) do |trg|
#       this.fields.each do |f|
#         if f.many then
#           src[f.name].each do |x|
#             trg[f.name] << recurse(f.type, x)
#           end
#         else
#           trg[f.name] = recurse(f.type, src[f.name])
#         end
#       end
#     end
#   end

#   def Primitive(this, v)
#     return v
#   end

# end

class Copy
  def initialize(factory, memo = {})
    @factory = factory
    @memo = memo
  end

  def copy(source)
    return nil if source.nil?
    target = @memo[source]
    if target
      #puts "FOUND #{source} => #{target}"
      return target 
    end
    klass = source.schema_class
    raise "Source does not have a schema_class #{source}" unless klass
    target = @factory[klass.name]
    @memo[source] = target

    klass.fields.each do |field|
      #puts "Copying #{field.name} #{source[field.name].class} #{source[field.name]}"
      next if field.computed
      if field.type.Primitive?
        target[field.name] = source[field.name]
      elsif !field.many
        target[field.name] = copy(source[field.name])
      else
        source[field.name].each do |x|
          target[field.name] << copy(x)
        end
      end
    end
    return target
  end
end


if __FILE__ == $0 then

  require 'schema/schemaschema'
  require 'tools/print'
  require 'schema/factory'
  
  newSchema = Copy.new(Factory.new(SchemaSchema.schema)).copy(SchemaSchema.schema)
  newSchema.finalize()
  
  Print.new.recurse(newSchema, SchemaSchema.print_paths)
  
  puts "#{newSchema.classes.class}"
  puts "WOA: #{newSchema.classes['Klass'].schema.name}"

end
