import 'demo/lambda/code/lambda'

input = "(({|f| {|a| (f (f a))}} {|x| x}) y)"

type = "lambda"
schema = Load::load("#{type}.schema")
grammar = Load::load("#{type}.grammar")
factory = Factory.new(schema)

ast = Parse2.parse(grammar, input, factory)
Print.print(ast)

interp = Lambda::EvalLambdaC.new
result = interp.eval(ast)
Print.print(result)
