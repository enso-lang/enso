
require 'grammar/grammargen'

class GrammarGrammar < GrammarGenerator

  start Grammar

  rule Grammar do
    alt [:Grammar], "grammar", {name: :sym}, "start", {start: ref(Rule)}, {rules: iter_star(Rule)}
  end

  rule Rule do
    alt [:Rule], {name: :sym}, "::=", {arg: Alt}
  end

  rule Alt do
    alt [:Alt], {alts: iter_sep(Create, "|")}
  end

  rule Create do
    alt [:Create], "[", {name: :sym}, "]", {arg: Sequence}
    alt Sequence
  end

  rule Sequence do
    alt [:Sequence], {elements: iter_star(Field)}
  end

  rule Field do
    alt [:Field], {name: :sym}, ":", {arg: Pattern}
    alt Pattern
  end

  rule Pattern do
    alt [:Value], {kind: "int"}
    alt [:Value], {kind: "str"}
    #alt [:Value], {kind: "sqstr"}
    alt [:Value], {kind: "real"}
    alt [:Value], {kind: "bool"}
    alt [:Value], {kind: "sym"}

    alt [:Code], "@", {code: :str}

    #alt [:Key], "key"

    alt [:Ref], {name: :sym}, "^"

    alt [:Lit], {value: :str} #, code("@case_sensitive = true")

    #alt [:Lit], {value: :sqstr}, code("@case_sensitive = false")

    alt [:Call], {rule: ref(Rule)}

    alt [:Regular], {arg: Pattern}, "*", code("@optional = true; @many = true; @sep = nil")

    alt [:Regular], {arg: Pattern}, "?", code("@optional = true; @sep = nil")

    alt [:Regular], {arg: Pattern}, "+", code("@many = true; @sep = nil")

    alt [:Regular], "{", {arg: Pattern}, {sep: :str}, "}", "*", code("@optional = true; @many = true")
    
    alt [:Regular], "{", {arg: Pattern}, {sep: :str}, "}", "+", code("@many = true") 

    alt "(", Alt, ")"
  end
end


if __FILE__ == $0 then
  require 'schema/schemaschema'
  require 'tools/print'
  require 'tools/copy'
  require 'schema/factory'

  Print.new.recurse(GrammarGrammar.grammar, GrammarSchema.print_paths)
  
  G = Copy.new(Factory.new(GrammarSchema.schema)).copy(GrammarGrammar.grammar)
  
  Print.new.recurse(G, GrammarSchema.print_paths)

end

