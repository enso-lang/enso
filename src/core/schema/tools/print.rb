
# This is a *generic* printing function, that can print a indented dump
# of any object. It uses the model to 

# obj: the object to be printed
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

  def self.print(obj, indent=0)
    self.new.recurse(obj, indent)
  end
  

  def recurse(obj, indent=0)
    if obj.nil?
      myputs "nil"
    else
      klass = obj.schema_class   # TODO: pass as an argument for partial evaluation
      myputs klass.name
      #myputs "#{klass.name} #{obj._id}"
      #myputs "FOO #{obj}
      indent += 2
      klass.fields.each do |field|
        #puts "FIELD: #{field}"
        #puts "FIELD.TYPE: #{field.type}"
        if field.type.Primitive?
          myprint " "*indent, field.name, ": ", obj[field.name], "\n"
        else
          if !field.many
            sub = obj[field.name]
            myprint " "*indent, field.name, ": "
            print1(field.traversal, sub, indent)
          else
            myprint " "*indent, field.name, "\n"
            subindent = indent + 2
            obj[field.name].each_with_index do |sub, i|
              myprint " "*subindent, "#", i, " "
              print1(field.traversal, sub, subindent)
            end
          end
        end
      end
    end
  end
  
  def print1(traversal, obj, indent)
    key = obj && ClassKey(obj.schema_class)
    if traversal  
      recurse(obj, indent)
    elsif key
      myprint obj[key.name], "\n"
    else
      myprint "<UNKNOWN NAME>", "\n"
    end
  end
  
end

if __FILE__ == $0 then
  require 'core/system/load/load'
  
  ss = Loader.load('schema.schema')
  sg = Loader.load('schema.grammar')
   
  Print.new.recurse(ss)  
  Print.new.recurse(sg)
end
