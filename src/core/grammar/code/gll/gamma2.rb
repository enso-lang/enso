
require 'core/system/boot/grammar_gen'

class Gamma2 < GrammarGenerator
  start S

  rule S do
    alt "b"
    alt S, S
    alt S, S, S
  end
end


class Exp < GrammarGenerator
  start E

  rule E do
    alt "x"
    alt E, "+", E
    alt E, "*", E
  end
end
