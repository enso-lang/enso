require "core/system/load/load"
require "core/schema/tools/print"
require "core/grammar/code/layout"

def eval(t)
  if t.schema_class.name == "App" then
    fun = eval(t.fun)
    sub = eval(t.sub)
    if fun.schema_class.name != "Lambda" then
      raise("Stuck: Trying to apply non-lambda")
    end
    return eval(subst(fun.body, fun.var, sub))
  else
    return t
  end
end

def subst(term, var, val)
  if term.schema_class.name == "Var" then
    return term.name==var ? val : term
  else
      if term.schema_class.name == "Const" then
        return term
      else
        if term.schema_class.name == "Lambda" then
          if term.var == var then
            return term
          else
            term.body = subst(term.body, var, val)
            return term
          end
        else
          if term.schema_class.name == "App" then
            term.fun = subst(term.fun, var, val)
            term.sub = subst(term.sub, var, val)
            return term
          end
        end
      end
    end
end

def fv(term)
end

expr = Loader.load("numerals.lambda")
puts("Term:")
DisplayFormat.print(Loader.load("lambda.grammar"), expr)
puts("evaluates to:")
DisplayFormat.print(Loader.load("lambda.grammar"), eval(expr))
