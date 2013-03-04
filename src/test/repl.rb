require 'core/system/utils/paths'

class Repl
  def self.run(model, &block)
    while true
      #display menu
      puts "\n\n"
      puts "Enter path to query current model or:"
      puts "  ? -- show entire model"
      puts "  ! -- edit a value"
      print "> "

      #ask input
      input = $stdin.gets.chomp
      if input=="?"
        Print.print model
      elsif input=="!"
        print "Path: "
        path = Paths::parse($stdin.gets.chomp)
        begin
          puts "Current value is: #{path.deref(model)}"
          begin
            print "New value: "
            val = $stdin.gets.chomp
            obj = path.object.deref(model)
            field = obj.schema_class.fields[path.fieldname]
            puts "obj=#{obj} field=#{field}"
            if field.type.Primitive?
              puts "primitive val"
              case field.type.name
              when "int"
                puts "integer"
                obj[field.name] = val.to_i
              when "str"
                obj[field.name] = val.to_s
              when "real"
                obj[field.name] = val.to_f
              when "bool"
                obj[field.name] = (val.capitalize=="True")
              end
            elsif !field.many
              valpath = Path::parse(val)
              obj[field.name] = valpath.deref(model)
            else  #non primitive many valued field
              puts "Currently unable to support editing many-valued fields"
            end
            puts "New value is: #{path.deref(model)}"
            yield model
          rescue
            puts "Invalid value!"
          end
        rescue
          puts "Invalid path!"
        end
      else #this is a path to query
        path = Paths::parse(input)
        begin
          puts path.deref(model)
        rescue
          puts "Invalid path!"
        end
      end
    
      puts "\n"
    end
  end  

end