
    def Let(this, recv, env, &block)
      env = {}.update(env)
      this.bindings.each do |binding|
        env[binding.name] = Delayed.new(self, binding, recv, env)
      end
      eval_seq(this.body, recv, env, &block)
    end


    class Delayed
      # Lazy bindings that self-destruct into values
      # they evaluate to

      def initialize(eval, binding, recv, env)
        @eval = eval
        @binding = binding
        @recv = recv
        @env = env
      end

      def name
        @binding.name
      end

      def force(env, &block)
        # no need to check whether
        # we should evaluate or not
        # since the Delayed thing is replaced
        # with what it evaluates to for caching

        if @binding.many then
          # don't cache (for now)
          # @env[name] = []
          @eval.eval(@binding.expression, @recv, @env) do |x, _|
            # @env[name] << x
            yield x, env
          end
        else
          obj = Stub.new
          @env[name] = obj
          @eval.eval(@binding.expression, @recv, @env) do |x, _|
            # detect stuff like "let x = x"
            raise "cycle without construction" if x.is_a?(Stub)
            obj.become!(x)            
          end
          yield obj, env
        end
      end
    end
