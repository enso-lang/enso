# This is a *generic* printing function, that can print a indented dump
# of any object. It uses the model to 

# obj: the object to be printed
# indent: amount of indent

class Print
  def initialize(output = $stdout)
    @output = output
  end

  def self.print(obj, indent=0)
    self.new.print(obj, indent)
  end
  
  def print(obj, indent=0, back_link=nil)
    if obj.nil?
      @output << "nil\n"
    else
      klass = obj.schema_class   # TODO: pass as an argument for partial evaluation
      @output << "#{klass.name}\n"
      indent += 2
      klass.fields.each do |field|
        next if field == back_link
        if field.type.Primitive?
          data = (field.type.name == "str") ? "\"#{obj[field.name]}\"" : obj[field.name]
          @output << "#{' '*indent}#{field.name}: #{data}\n"
        else
          if !field.many
            sub = obj[field.name]
            @output << "#{' '*indent}#{field.name}: "
            print1(field.traversal, sub, indent, field.inverse)
          else
            next if obj[field.name].empty?
            @output << "#{' '*indent}#{field.name}\n"
            subindent = indent + 2
            obj[field.name].each_with_index do |sub, i|
              @output << "#{' '*subindent}##{i} "
              print1(field.traversal, sub, subindent, field.inverse)
            end
          end
        end
      end
    end
  end
  
  def print1(traversal, obj, indent, back_link)
    if obj.nil?
      @output << "nil\n"
    elsif traversal  
      print(obj, indent, back_link)
    elsif key = ClassKey(obj.schema_class)
      @output << "#{obj[key.name]}\n"
    else
      @output << "<UNKNOWN NAME>\n"
    end
  end
end

if __FILE__ == $0 then
  require 'core/system/load/load'
  
  ss = Loader.load('schema.schema')
  sg = Loader.load('schema.grammar')
   
  Print.print(ss)  
  Print.print(sg)
end
