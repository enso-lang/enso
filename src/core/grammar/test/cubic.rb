
require 'core/grammar/parse/gll'
require 'core/grammar/parse/origins'
require 'core/schema/tools/print'
require 'benchmark'

#TODO: convert to XML
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
  1.step(50, 5) do |i|
    source = ('b ' * i).rstrip
    t = Benchmark.realtime { GLL.parse(source, grammar, grammar.start, org) }
    puts "#{i} #{t}"
  end
end
