

require 'core/web/code/dispatch'
require 'core/web/code/result'
require 'core/schema/tools/print'

module Web::Eval
  class Expr
    include Dispatch

    def Str(this, env, errors)
      Result.new(this.value)
    end

    def Int(this, env, errors)
      Result.new(this.value.to_i)
    end

    def Var(this, env, errors)
      # TODO: pass errors in the env
      if this.name == 'errors' then
        Record.new(errors)
      else
        env[this.name]
      end
    end

    def Concat(this, env, errors)
      lhs = eval(this.lhs, env, errors)
      rhs = eval(this.rhs, env, errors)
      Result.new(lhs.value.to_s + rhs.value.to_s)
    end

    def Equal(this, env, errors)
      lhs = eval(this.lhs, env, errors)
      rhs = eval(this.rhs, env, errors)
      Result.new(lhs.value == rhs.value)
    end

    def In(this, env, errors)
      lhs = eval(this.lhs, env, errors)
      rhs = eval(this.rhs, env, errors) 
      rhs.value.each do |x|
        if lhs.value == x then
          return Result.new(true)
        end
      end
      Result.new(false)
    end

    def Address(this, env, errors)
      eval(this.exp, env, errors).address
    end

    def New(this, env, errors)
      # TODO: get rid of hard-wired root here
      Ref.create(this.class, env['root'].value)
    end

    def Field(this, env, errors)
      r = eval(this.exp, env, errors)
      puts "RESULT = #{r}"
      r.field(this.name)
    end

    def Subscript(this, env, errors)
      eval(this.obj, env, errors).subscript(eval(this.exp, env, errors).value)
    end

    def Call(this, env, errors)
      Print.print(this)
      call = eval(this.exp, env, errors)
      args = this.args.map do |arg|
        eval(arg, env, errors)
      end
      call.bind(args)
    end

    def List(this, env, errors)
      elts = this.elements.map do |elt|
        eval(elt, env, errors)
      end
      List.new(elts)
    end

  end
end
