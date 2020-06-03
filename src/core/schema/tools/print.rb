# This is a *generic* printing function, that can print a indented dump
# of any object. It uses the model to 

# obj: the object to be printed
# indent: amount of indent

module Print
  
  def self.print(obj)
    PrintC.print(obj)
  end

  class PrintC
    def initialize(output = $stdout, depth = nil)
      @output = output
      @depth = depth
    end

    def self.print(obj, depth = nil)
      self.new($stdout, depth).print(obj)
    end
  
    def self.to_s(obj, depth = nil)
      output = ""
      self.new(output, depth).print(obj)
      output
    end
      
    def print(obj, indent=0, back_link=nil)
      if !obj.respond_to?(:schema_class) then
        @output << "#{obj}\n"
      elsif obj.nil?
        @output << "nil\n"
      else
        klass = obj.schema_class   # TODO: pass as an argument for partial evaluation
        @output << "#{klass.name} #{obj.identity}\n"
        indent += 2
        klass.fields.each do |field|
          if field != back_link
            if field.type.is_a?("Primitive")
              data = (field.type.name == "str") ? "\"#{obj[field.name]}\"" : obj[field.name]
              @output << "#{' '.repeat(indent)}#{field.name}: #{data}\n"
            else
              if !field.many
                sub = obj[field.name]
                @output << "#{' '.repeat(indent)}#{field.name}: "
                if @depth && indent > @depth*2
                  @output << "...\n"
                else
                  print1(field.traversal, sub, indent, field.inverse)
                end
              elsif !obj[field.name].empty?
                @output << "#{' '.repeat(indent)}#{field.name}"
                subindent = indent + 2
                if @depth && indent > @depth*2
                  @output << " ...\n"
                else
                  @output << "\n"
                  obj[field.name].each_with_index do |sub, i|
                    @output << "#{' '.repeat(subindent)}##{i} "
                    print1(field.traversal, sub, subindent, field.inverse)
                  end
                end
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
      else
        @output << "#{obj._path}\n"
      end
    end
  end
end