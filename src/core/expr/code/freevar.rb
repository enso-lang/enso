require 'core/expr/code/eval'

module FreeVar
  module FreeVarExpr
    #Determine the set of unbounded variables in this expr
    #that need to be supplied by the environment.
    #There are no assumptions as to the type of EFields,
    #so they can be MObjects or Ruby objects or even arrays
  
    #Function calls do not work properly here since functions
    #can be defined outside of the expression (they are ALWAYS
    #defined externally if this is Expr without Impl)
  
    include Eval::EvalExpr
    include Lvalue::LValueExpr
    
    include Interpreter::Dispatcher    
      
    def depends(obj)
      dispatch(:depends, obj)
    end
    
    def depends_EField(e, fname)
      [*depends(e)] 
    end
  
    def depends_EVar(name)
      (@D[:bound].include?(name) || name == "self") ? [] : [Lvalue::Address.new(@D[:env], name)]
    end
  
    def depends_ELambda(body, formals)
      bound2 = @D[:bound].clone
      formals.each{|f|bound2<<depends(f)}
      dynamic_bind bound: bound2 do
        depends(body)
      end
    end
    
    def depends_Formal(name)
      name
    end
  
    def depends_?(type, fields, args)
      res = []
      type.fields.each do |f|
        if f.traversal && !f.type.Primitive? && fields[f.name]
          if !f.many
            res += depends(fields[f.name])
          else
            fields[f.name].each {|o| res += depends(o)}
          end
        end
      end
      res
    end
  end
  
  class FreeVarExprC
    include FreeVarExpr  
    def initialize
    end
  end
end