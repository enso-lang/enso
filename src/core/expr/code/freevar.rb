require 'core/expr/code/eval'

module FreeVarExpr
  #Determine the set of unbounded variables in this expr
  #that need to be supplied by the environment.
  #There are no assumptions as to the type of EFields,
  #so they can be MObjects or Ruby objects or even arrays

  #Function calls do not work properly here since functions
  #can be defined outside of the expression (they are ALWAYS
  #defined externally if this is Expr without Impl)

  include EvalExpr
  include LValueExpr
  
  operation :depends

  def depends_EField(e, fname, args={})
    [*e.depends(args)] 
  end

  def depends_EVar(name, args={})
    args[:bound].include?(name) ? [] : [Address.new(args[:env], name)]
  end

  def depends_ELambda(body, formals, args={})
    bound = args[:bound].clone
    formals.each{|f|bound<<f.depends}
    body.depends(args+{:bound=>bound})
  end
  
  def depends_Formal(name, args={})
    name
  end

  def depends_?(type, fields, args={})
    res = []
    type.fields.each do |f|
      next if !f.traversal or f.type.Primitive?
      next if f.optional and fields[f.name].nil?
      if !f.many and !f.type.Primitive?
        res += fields[f.name].depends(args)
      else
        fields[f.name].each {|o| res += o.depends(args)}
      end
    end
    res
  end
end


