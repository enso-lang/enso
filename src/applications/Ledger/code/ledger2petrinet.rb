
require 'core/system/load/load'
require 'core/schema/code/factory'

class Ledger2PetriNet
  PN_SCHEMA = Loader.load('petrinet.schema')

  def self.ledger2petrinet(ledger)
    self.new.ledger2petrinet(ledger)
  end

  def initialize
    @pnf = Factory.new(PN_SCHEMA)
  end
  

  def ledger2petrinet(ledger)
    pn = @pnf.PetriNet

    as = {}
    ledger.accounts.each do |a|
      as[a] = @pnf.Place(a.name)
      pn.nodes << u = as[a]
      pn.nodes << ru = @pnf.Place("registered_#{a.name}")
      pn.nodes << au = @pnf.Place("absent_#{a.name}")
      pn.nodes << ar = @pnf.Place("absent_registered_#{a.name}")

      # TODO: illicit stuff
    end

    trs = {}
    ledger.transactions.each do |t|
      trs[t] = d = @pnf.Transition(t.name)
      pn.nodes << trs[t]

      pn.nodes << grf = @pnf.Transition("get_ready_for_#{t.name}")

      pn.nodes << rf = @pnf.Place("ready_for_#{t.name}")
      pn.nodes << dn = @pnf.Place("done_#{t.name}")
      pn.nodes << ar = @pnf.Place("absent_registrated_#{t.name}")
      pn.nodes << r = @pnf.Place("registrated_#{t.name}")
      
      pn.arcs << @pnf.Arc(1, rf, d)#
      pn.arcs << @pnf.Arc(1, dn, grf)#
      pn.arcs << @pnf.Arc(1, ar, d)

      pn.arcs << @pnf.Arc(-1, rf, grf)#
      pn.arcs << @pnf.Arc(-1 ,dn, d)
      pn.arcs << @pnf.Arc(-1 ,r, d)

      t.transfers.each do |t|
        a = as[t.account] # unit place
        pn.arcs << @pnf.Arc(t.amount, a, d)
      end

    end

    return pn
  end

end
