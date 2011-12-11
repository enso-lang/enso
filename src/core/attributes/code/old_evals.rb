
    def _eval_primitive_attribute(attr, recv, env, args, &block)
      new_env = bind_formals(attr, env, args)
      key = [recv, attr.name, args]
      if !@memo[key] then
        @memo[key] = attr.default && attr.default.value 
        eval(attr.result, recv, new_env) do |val, _|
          @memo[key] = val
        end
        change = false
        while !change do
          x = nil
          eval(attr.result, recv, new_env) do |val, _|
            x = val
          end
          
        end
      end
      yield @memo[key], env
    end

    def _eval_collection_attribute(attr, recv, env, args, &block)
      new_env = bind_formals(attr, env, args)
      key = [recv, attr.name, args]
      if !@memo[key] then
        @memo[key] = []
        eval(attr.result, recv, new_env) do |elt, _|
          @memo[key] << elt
        end
      end
      @memo[key].each do |elt|
        yield elt, env
      end
    end

    def _eval_object_attribute(attr, recv, env, args, &block)
      new_env = bind_formals(attr, env, args)
      key = [recv, attr.name, args]
      if !@memo[key] then
        @memo[key] = Stub.new
        eval(attr.result, recv, new_env) do |new, _|
          @memo[key].become!(new)
        end
      end
      yield @memo[key], env
    end
