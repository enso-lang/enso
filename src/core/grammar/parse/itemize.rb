

module ItemizeGrammar
  def self.itemize(grammar)
    fact = grammar._graph_id
    grammar.rules.each do |rule|
      rule.arg.alts.each do |alt|
        # assume alt is a seq because of normalization
        n = alt.elements.size
        if n == 0 then
          alt.elements << fact.EpsilonEnd(nil, rule)
          # elsif n == 1 && alt.elements[0].Terminal? then
          #   term = fact.TerminalEnd
          #   term.nxt = rule
          #   alt.elements[0].nxt = term
        else
          0.upto(n-2) do |i|
            alt.elements[i].nxt = alt.elements[i+1]
            if i > 0 then
              alt.elements[i].prev = alt.elements[i-1]
            end
          end
          # reusing nxt here for the "to pop" symbol
          alt.elements[n-1].nxt = fact.End(nil, rule)
          alt.elements[n-1].prev = alt.elements[n-2] if n > 1
        end
      end
    end  
  end
end

