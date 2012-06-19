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

  def depends_EField(e, fname, args={})
    [*depends(e, args)] + begin
      [Address.new(ObjEnv.new(self.eval(e, args)), fname)]
    rescue
      []
    end
  end

  def depends_EVar(name, args={})
    args[:bound].include?(name) ? [] : [Address.new(args[:env], name)]
  end

  def depends_ELambda(body, formals, args={})
    bound = args[:bound].clone
    formals.each{|f|bound<<f.name}
    depends(body, args+{:bound=>bound})
  end

  def depends_?(fields, type, args={})
    res = []
    type.fields.each do |f|
      next if !f.traversal or f.type.Primitive?
      next if f.optional and fields[f.name].nil?
      if !f.many
        res += depends(fields[f.name], args)
      else
        fields[f.name].each {|o| res += depends(o, args)}
      end
    end
    res
  end
end


