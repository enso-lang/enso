
require 'core/grammar/code/gll/glldebug'
require 'core/grammar/code/origins'
require 'core/schema/tools/print'
require 'benchmark'

require 'core/system/boot/grammar_gen'

class Gamma2 < GrammarGenerator
  start S

  rule S do
    alt "b"
    alt S, S
    alt S, S, S
  end
end

if __FILE__ == $0 then
  grammar = Gamma2.grammar
  org = Origins.new('', '-')
  1.upto(100) do |i|
    source = ('b ' * i).rstrip
    t = Benchmark.realtime { GLL.parse(source, grammar, grammar.start, org) }
    puts "#{i} #{t}"
  end
end
