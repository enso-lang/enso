
require 'core/semantics/factories/combinators'
require 'core/semantics/factories/test/ext-expr'


def test_permutations(base, evals, term, load)
  errs = []
  count = 0
  (1..evals.length).each do |n|
    begin
      evals.permutation(n) do |perm|
        perm.length.times do |i|
          # insert base separately; should always be there
          lst = perm.clone
          lst.insert(i, base)
          count += 1
          f = lst[1..-1].inject(lst.first.new) { |cur, e| Extend.new(e.new, cur) }
          puts "### Combining #{perm} with base #{base} at #{i}:\n\t#{f}"
          
          x = load.new(f).fold(term)
          begin 
            puts x.eval
          rescue Exception => e
            errs << e
            puts "Error factory: #{f}"
          end
        end
      end
    end
  end
  puts "#{errs.length} exceptions in #{count} permutations of #{evals} with #{base}"
  ecs = []
  errs.each do |e|
    ecs |= [e.class]
  end
  puts "\tTypes: #{ecs}"
end

if __FILE__ == $0 then
  Ex1 = Add.new(Const.new(1), Const.new(2))
  Ex2 = Add.new(Const.new(5), Ex1)

  test_permutations(Eval, [Count, Render, Debug, Memo, Trace, PrintConst], 
                    Ex1, FFold)
end


