

require 'core/web/code/dispatch'
require 'core/web/code/result'

module Web::Eval
  class Expr
    include Dispatch

    def EStrConst(this, env)
      Result.new(this.val)
    end

    def EIntConst(this, env)
      Result.new(this.val.to_i)
    end

    def EVar(this, env)
      env[this.name]
    end

    def Concat(this, env)
      lhs = eval(this.lhs, env)
      rhs = eval(this.rhs, env)
      Result.new(lhs.value.to_s + rhs.value.to_s)
    end

    def Equal(this, env)
      lhs = eval(this.lhs, env)
      rhs = eval(this.rhs, env)
      Result.new(lhs.value == rhs.value)
    end

    def In(this, env)
      lhs = eval(this.lhs, env)
      rhs = eval(this.rhs, env) 
      rhs.value.each do |x|
        if lhs.value == x then
          return Result.new(true)
        end
      end
      Result.new(false)
    end

    def Address(this, env)
      eval(this.exp, env).address
    end

    def New(this, env)
      Ref.create(this.class, env.root)
    end

    def EField(this, env)
      r = eval(this.e, env)
      r.field(this.fname)
    end

    def Subscript(this, env)
      eval(this.obj, env).subscript(eval(this.exp, env).value)
    end

    def Call(this, env)
      call = eval(this.exp, env)
      args = this.args.map do |arg|
        eval(arg, env)
      end
      call.bind(args)
    end

    def List(this, env)
      elts = this.elements.map do |elt|
        eval(elt, env)
      end
      List.new(elts)
    end

  end
end
