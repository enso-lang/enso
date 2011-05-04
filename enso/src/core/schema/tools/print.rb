
# This is a *generic* printing function, that can print a indented dump
# of any object. It uses the model to 

# obj: the object to be printed
# paths: this is s nested record type that guides the printing process.
#   the keys tell the printer which fields to traverse from the main object
#   the values are the paths for the subobject
# indent: amount of indent
# inverse: an internal argument that tells what field was just traveresed,
#   so that its inverse will not be printed on the subobjects. This just
#   cleans up the printout a little

class Print
  def initialize(output = $stdout)
    @output = output
  end

  def myputs(arg)
    @output << "#{arg}\n"
  end

  def myprint(*args)
    @output << args.join('')
  end

  def self.print(obj, paths={}, indent=0, visited=[])
    self.new.recurse(obj, paths, indent, visited)
  end
  

  def recurse(obj, paths={}, indent=0, visited=[])
    if obj.nil?
      myputs "nil"
    else
      visited.push obj
      klass = obj.schema_class   # TODO: pass as an argument for partial evaluation
      myputs klass.name
      #myputs "#{klass.name} #{obj._id}"
      #myputs "FOO #{obj} p=#{paths} i=#{visited}"
      indent += 2
      klass.fields.each do |field|
        if field.type.Primitive?
          myprint " "*indent, field.name, ": ", obj[field.name], "\n"
        else
          sub_path = paths[field.name.to_sym]

          if sub_path || !field.inverse ||
                (!field.many && (obj[field.name].nil? || key(obj[field.name].schema_class)))
            if !field.many
              sub = obj[field.name]
              use_key = sub_path.nil? && !sub.nil? && key(sub.schema_class)
              if !visited.include?(sub) || visited[-2] != sub && use_key
                myprint " "*indent, field.name, ": "
                print1(use_key, sub, sub_path, indent, visited)
              end
            else
              myprint " "*indent, field.name, "\n"
              subindent = indent + 2
              obj[field.name].each_with_index do |sub, i|
                myprint " "*subindent, "#", i, " "
                use_key = sub_path.nil? && key(sub.schema_class)
                print1(use_key, sub, sub_path, subindent, visited)
              end
            end
          end
        end
      end
      visited.pop
    end
  end
  
  def print1(use_key, obj, path, indent, visited)
    if use_key  
      # TODO: annoying that we need to know actual type, not just declared type
      # This is because we don't have field inheritance in the base schema
      myprint obj[key(obj.schema_class).name], "\n"
    else
      recurse(obj, path || {}, indent, visited)
    end
  end
  
  def key(klass)
    klass.fields.find { |f| f.key && f.type.Primitive? }
  end  

end

if __FILE__ == $0 then
  require 'schema/schemaschema'
  # Print.recurse(SchemaSchema.schema) # this also works
   
  Print.new.recurse(SchemaSchema.schema, SchemaSchema.print_paths)
  
  require 'grammar/grammarschema'  
  Print.new.recurse(GrammarSchema.schema, SchemaSchema.print_paths)
end
