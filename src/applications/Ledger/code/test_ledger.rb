

require 'core/system/load/load'
require 'core/grammar/code/layout'

require 'applications/petrinet/code/matrix'
require 'applications/petrinet/code/petrinet2dot'
require 'applications/ledger/code/ledger2petrinet'

l = Loader.load('bicycle.ledger')
lg = Loader.load('ledger.grammar')

DisplayFormat.print(lg, l)

rks = l.accounts.map { |a| a.name.to_sym }
cks = l.transactions.map { |t| t.name.to_sym }

p rks
p cks

m = Matrix.make({}, rks, cks)

l.transactions.each do |tr|
  tr.transfers.each do |t|
    m.set!(t.account.name.to_sym, tr.name.to_sym, t.amount)
  end
end

puts "MATRIX"
puts m

puts "TRANSPOSE"
puts m.transpose


v = Vector.make({}, cks)

l.transactions.each do |tr|
  v[tr.name.to_sym] = tr.proration
end


puts "Value jump"

puts m * v


pn = Ledger2PetriNet.ledger2petrinet(l)

pg = Loader.load('petrinet.grammar')

DisplayFormat.print(pg, pn)


File.open('bla.dot', 'w') do |f|
  PetriNet2Dot.todot(pn, f)
end
