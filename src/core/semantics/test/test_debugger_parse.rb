require 'core/system/load/load'
require 'core/semantics/interpreters/debug'
require 'core/semantics/test/parse'

#Fibo is the fibonacci function. Source found in core/expr/test/fibo.impl
# Note that the whole program is surrounded by an implicit block (EBlock)
# with two statements: the fun def and the fun call

Cache.clean('lambda.grammar') #need to clean cache to get origin tracking
sm = Load::load('lambda.grammar')
FindModel::FindModel.find_model('lambda.grammar') {|path| $file = IO.readlines(path)}

#EvalCommandC.new is the non-debug version
# DebugMod is parameterized by the interpreter (ie EvalCommand),

  class DebugParseGrammarC
    include Parse2::ParseGrammar
    include Debug::Debug
    def parse(obj)
      wrap(:parse, :debug, obj)
    end
  end


input = "(({|f| {|a| (f (f a))}} {|x| x}) y)"

type = "lambda"
schema = Load::load("#{type}.schema")
grammar = sm
factory = Factory.new(schema)

interp = DebugParseGrammarC.new
ast = interp.dynamic_bind input: input, factory:factory, stack:[], this:sm do
  interp.parse(sm)
end
Print.print(ast)

