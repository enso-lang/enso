require 'core/system/load/load'
require 'core/semantics/interpreters/debug'
require 'demo/lambda/code/parse'

Cache.clean('lambda.grammar') #need to clean cache to get origin tracking
sm = Load::load('lambda.grammar')

class ParseGrammarC
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

interp = ParseGrammarC.new
ast = interp.dynamic_bind input: input, factory:factory do
  interp.parse(sm)
end
Print.print(ast)

