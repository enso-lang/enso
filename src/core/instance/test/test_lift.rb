
  require 'core/instance/code/lift'
  require 'core/grammar/code/parse'
  require 'core/grammar/code/layout'
  require 'core/schema/tools/print'

  require 'core/system/boot/grammar_grammar'
  obj = Parse.load_file('core/grammar/models/grammar.grammar', GrammarGrammar.grammar,
                        GrammarSchema.schema)

  p obj
  ast = Lift.lift(obj, {:rules => {}})

  Print.print(ast)

  ig = Loader.load('instance.grammar')

  #DisplayFormat.print(ig, ast)

  ast2 = Lift.lift(ast)
  #DisplayFormat.print(ig, ast2)

  obj = Instantiate.instantiate(Factory.new(GrammarSchema.schema), ast)
  #Print.print(obj)

  DisplayFormat.print(GrammarGrammar.grammar, obj)

  