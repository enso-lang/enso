require 'core/expr/code/eval'
require 'core/expr/code/lvalue'
require 'core/semantics/code/interpreter'

module Freevar
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
      dispatch_obj(:depends, obj)
    end
    
    def depends_EField(obj)
      #[*depends(obj.e)]
      depends(obj.e) 
    end
  
    def depends_EVar(obj)
      (@D[:bound].include?(obj.name) || obj.name == "self") ? [] : [Lvalue::Address.new(@D[:env], obj.name)]
    end
  
    def depends_ELambda(obj)
      bound2 = @D[:bound].clone
      obj.formals.each{|f|bound2<<depends(f)}
      dynamic_bind(bound: bound2) do
        depends(obj.body)
      end
    end
    
    def depends_Formal(obj)
      obj.name
    end
  
    def depends_?(obj)
      res = []
      type = obj.schema_class
      type.fields.each do |f|
        if f.traversal && !f.type.Primitive? && obj[f.name]
          if !f.many
            res = res.concat( depends(obj[f.name]) )
          else
            obj[f.name].each {|o| res = res.concat(depends(o)) }
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

  def self.depends(obj, args={})
    interp = FreeVarExprC.new
    interp.dynamic_bind args do
      interp.depends(obj)
    end
  end
end