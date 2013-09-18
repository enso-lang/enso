




    # this is a helper method that can be overiden    
    def _create_initialize_method(klass, c)
      c.define_method(:initialize) do |*args|

        # initialize    
        klass.fields.each_with_index do |fld, i|
          if i < args.size
            if fld.many then
              args[i].each do |value|
                self[fld.name] << value
              end
            else
              self[fld.name] = args[i]
            end
          end
        end

      end 
    end
